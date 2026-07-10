"""The assessment orchestrator: audio bytes + reference verse → result.

Ties the whole pipeline together:
  preprocess → transcribe → char posteriors → forced align →
  per-letter acoustics → letter alignment (ref vs heard) → tajweed rules
  → scoring → structured AssessmentResult.

Import-light at module load: the ML modules (asr, acoustics) are only
touched inside `assess`, so this file — and `main` — import cleanly even
when torch/whisper aren't installed. In that case `assess` raises
ModelsUnavailable and the API answers 503.
"""

from __future__ import annotations

from . import arabic
from .align import align_letters
from .schemas import (
    AssessmentResult,
    LetterResult,
    LetterStatus,
    Severity,
    TajweedError,
    Timing,
    WordResult,
)
from .scoring import compute_score
from .tajweed import analyze


def _letter_results(
    tokens, ac, ops
) -> tuple[list[LetterResult], dict[int, str]]:
    """Merge acoustic evidence + ref/hyp alignment into per-letter rows.

    Returns the rows and a map letter_index → status for the rule pass.
    """
    # Map reference letter index → alignment op that consumed it.
    op_by_ref: dict[int, object] = {}
    for op in ops:
        if op.ref_index is not None:
            op_by_ref[op.ref_index] = op

    rows: list[LetterResult] = []
    status_by_index: dict[int, str] = {}
    for tok in tokens:
        la = ac.by_index(tok.index)
        op = op_by_ref.get(tok.index)
        heard = la.heard if la and la.recited else None

        if op is not None and op.op == "delete":
            status = LetterStatus.missing
        elif op is not None and op.op == "confuse":
            status = LetterStatus.substituted
        elif op is not None and op.op == "sub":
            status = LetterStatus.incorrect
        elif la is None or not la.recited:
            status = LetterStatus.missing
        elif la.gop < 0.20:
            status = LetterStatus.incorrect
        elif la.gop < 0.45:
            status = LetterStatus.unclear
        else:
            status = LetterStatus.correct

        status_by_index[tok.index] = status.value
        rows.append(LetterResult(
            index=tok.index,
            letter=tok.letter,
            heard=heard,
            status=status,
            confidence=round(la.gop, 3) if la else 0.0,
            start=la.start if la else None,
            end=la.end if la else None,
        ))

    # Extra (inserted) letters the reader added.
    for op in ops:
        if op.op == "insert" and op.hyp is not None:
            rows.append(LetterResult(
                index=-1,
                letter=op.hyp,
                heard=op.hyp,
                status=LetterStatus.extra,
                confidence=0.5,
                feedback="Ortiqcha harf qo‘shildi.",
            ))
    return rows, status_by_index


def _word_results(reference: str, transcript: str, words) -> list[WordResult]:
    ref_words = arabic.words(reference)
    hyp_words = arabic.words(transcript)
    ops = align_letters(ref_words, hyp_words)  # reuse aligner on word tokens
    rows: list[WordResult] = []
    hyp_time = {i: w for i, w in enumerate(words)}
    for op in ops:
        if op.ref_index is None:
            continue
        idx = op.ref_index
        expected = ref_words[idx]
        if op.op == "match":
            status = "correct"
            heard = expected
        elif op.op in ("confuse", "sub"):
            status = "substituted" if op.op == "confuse" else "incorrect"
            heard = op.hyp
        else:
            status = "missing"
            heard = None
        w = hyp_time.get(op.hyp_index) if op.hyp_index is not None else None
        rows.append(WordResult(
            index=idx,
            expected=expected,
            heard=heard,
            status=status,  # type: ignore[arg-type]
            start=w.start if w else None,
            end=w.end if w else None,
            confidence=round(w.prob, 3) if w else 0.6,
        ))
    return rows


def _tajweed_errors(findings) -> list[TajweedError]:
    errors: list[TajweedError] = []
    for f in findings:
        if f.applied:
            continue  # only surface *failed* rules as errors
        errors.append(TajweedError(
            rule=f.rule,
            severity=Severity(f.severity),
            letter_index=f.letter_index,
            start=f.start,
            end=f.end,
            expected=f.expected,
            observed=f.observed,
            feedback=f.feedback,
        ))
    return errors


def _attach_rules(letters, findings) -> None:
    """Annotate letter rows with the first failed rule at that index."""
    failed_by_index: dict[int, str] = {}
    for f in findings:
        if not f.applied and f.letter_index is not None:
            failed_by_index.setdefault(f.letter_index, f.rule)
            # also carry feedback onto the letter row
    for row in letters:
        rule = failed_by_index.get(row.index)
        if rule and row.rule is None:
            row.rule = rule


def _summary(score, letters, errors) -> list[str]:
    lines = [f"Umumiy ball: {score}/100."]
    missing = sum(1 for l in letters if l.status == LetterStatus.missing)
    subs = sum(1 for l in letters if l.status == LetterStatus.substituted)
    if missing:
        lines.append(f"{missing} ta harf o‘qilmadi.")
    if subs:
        lines.append(f"{subs} ta harf boshqa harfga almashtirildi.")
    if errors:
        top = errors[0]
        lines.append(f"Asosiy tajvid xatosi: {top.rule} — {top.feedback}")
    if not missing and not subs and not errors:
        lines.append("Ajoyib! Sezilarli xato topilmadi.")
    return lines


def assess(audio: bytes, reference: str) -> AssessmentResult:
    """Full pipeline. Raises asr.ModelsUnavailable if the ML stack is down."""
    # Lazy imports so the module graph is safe without torch installed.
    from . import acoustics as ac_mod
    from . import asr, audio as audio_mod

    processed = audio_mod.preprocess(audio)
    transcription = asr.transcribe(processed.samples)
    cp = asr.char_posteriors(processed.samples)

    tokens = arabic.tokenize(reference)
    acoustics = ac_mod.build_acoustics(
        tokens, cp, processed.speech_segments
    )

    # Letter-level alignment: reference vs what wav2vec2 actually heard.
    ref_letters = [t.letter for t in tokens]
    heard_letters = [
        la.heard for la in acoustics.letters if la.recited and la.heard
    ]
    ops = align_letters(ref_letters, heard_letters)

    findings = analyze(tokens, acoustics)
    breakdown = compute_score(ops, findings, ac_mod.mean_gop(acoustics))

    letters, _ = _letter_results(tokens, acoustics, ops)
    _attach_rules(letters, findings)
    words = _word_results(reference, transcription.text, transcription.words)
    errors = _tajweed_errors(findings)

    wpm = None
    if processed.speech_seconds > 0 and words:
        wpm = round(len(words) / (processed.speech_seconds / 60.0), 1)

    return AssessmentResult(
        score=breakdown.score,
        correct=breakdown.correct,
        transcript=transcription.text,
        reference=reference,
        confidence=round(breakdown.confidence, 3),
        letters=letters,
        words=words,
        tajweed_errors=errors,
        timing=Timing(
            audio_seconds=round(processed.duration, 2),
            speech_seconds=round(processed.speech_seconds, 2),
            words_per_minute=wpm,
        ),
        feedback=_summary(breakdown.score, letters, errors),
        engine="faster-whisper + wav2vec2-ctc",
    )
