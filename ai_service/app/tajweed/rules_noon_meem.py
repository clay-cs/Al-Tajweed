"""Noon-sakinah / tanwin and meem-sakinah rules.

Covers: Noon Sakinah, Meem Sakinah, Izhar, Ikhfa, Idgham (with & without
ghunnah — i.e. Ma'a/Bila Ghunnah), Iqlab, and Ghunnah duration.

The positional detection (which rule applies where) is fully deterministic
from the vocalised text. Whether it was *applied correctly* uses the
acoustic ghunnah/duration signal when present, and degrades to a neutral
"reminder" finding when audio evidence is missing.
"""

from __future__ import annotations

from ..arabic import (
    IDGHAM_GHUNNAH,
    IDGHAM_NO_GHUNNAH,
    IKHFA_LETTERS,
    IQLAB_LETTER,
    SUKUN,
    THROAT_LETTERS,
    Token,
)
from .engine import Acoustics, RuleFinding, Rule, register

# Ghunnah must be held ~2 harakat. Below this fraction of it → too short.
GHUNNAH_MIN_HARAKAH = 1.4


def _next_letter(tokens: list[Token], i: int) -> Token | None:
    return tokens[i + 1] if i + 1 < len(tokens) else None


def _is_noon_sakinah(tok: Token) -> bool:
    return tok.letter == "ن" and (tok.has_sukun or tok.tanwin is None and False)


def _carries_tanwin(tok: Token) -> bool:
    return tok.tanwin is not None


def _ghunnah_finding(
    rule: str, idx: int, ac: Acoustics, ok_feedback: str
) -> RuleFinding:
    """Shared ghunnah-duration check for a nasalised letter at `idx`."""
    la = ac.by_index(idx)
    if la is None or not la.recited:
        return RuleFinding(
            rule=rule, letter_index=idx, applied=True, severity="low",
            feedback=ok_feedback,
        )
    if la.harakah >= GHUNNAH_MIN_HARAKAH:
        return RuleFinding(
            rule=rule, letter_index=idx, applied=True, severity="low",
            feedback=ok_feedback, expected="≥2 harakah ghunnah",
            observed=f"{la.harakah:.1f} harakah", start=la.start, end=la.end,
        )
    sev = "high" if la.harakah < 0.7 else "medium"
    return RuleFinding(
        rule=rule, letter_index=idx, applied=False, severity=sev,
        feedback="G‘unna (burun tovushi) yetarlicha cho‘zilmadi — "
                 "kamida 2 harakat ushlang.",
        expected="≥2 harakah ghunnah",
        observed=f"{la.harakah:.1f} harakah", start=la.start, end=la.end,
    )


@register
class NoonSakinahRule(Rule):
    """Classifies every noon-sakinah / tanwin and checks its realisation."""

    name = "Noon Sakinah"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            is_noon = tok.letter == "ن" and tok.has_sukun
            is_tanwin = _carries_tanwin(tok)
            if not (is_noon or is_tanwin):
                continue
            nxt = _next_letter(tokens, i)
            if nxt is None:
                continue
            n = nxt.letter

            if n in THROAT_LETTERS:
                out.append(RuleFinding(
                    "Izhar", i, True, "low",
                    "Izhor: nun aniq, g‘unnasiz talaffuz qilinadi.",
                ))
            elif n == IQLAB_LETTER:
                out.append(self._iqlab(i, acoustics))
            elif n in IDGHAM_GHUNNAH:
                out.append(self._idgham_ghunnah(i, acoustics))
            elif n in IDGHAM_NO_GHUNNAH:
                out.append(RuleFinding(
                    "Idgham Bila Ghunnah", i, True, "low",
                    "Idg‘om bilo g‘unna: nun keyingi harfga g‘unnasiz "
                    "qo‘shiladi.",
                ))
            elif n in IKHFA_LETTERS:
                out.append(self._ikhfa(i, acoustics))
        return out

    def _iqlab(self, idx, ac):
        base = _ghunnah_finding(
            "Iqlab", idx, ac,
            "Iqlob: nun mim tovushiga aylanib, g‘unna bilan aytiladi.",
        )
        base.rule = "Iqlab"
        return base

    def _idgham_ghunnah(self, idx, ac):
        base = _ghunnah_finding(
            "Idgham Ma'a Ghunnah", idx, ac,
            "Idg‘om ma’a g‘unna: nun keyingi harfga g‘unna bilan qo‘shildi.",
        )
        return base

    def _ikhfa(self, idx, ac):
        base = _ghunnah_finding(
            "Ikhfa", idx, ac,
            "Ixfo: nun yashirilib, g‘unna bilan talaffuz qilindi.",
        )
        if not base.applied:
            base.feedback = "Ixfo to‘g‘ri bajarilmadi — nunni yashirib, "
            base.feedback += "g‘unnani 2 harakat ushlang."
        return base


@register
class GhunnahRule(Rule):
    """Shadda-noon and shadda-meem always carry a full ghunnah."""

    name = "Ghunnah"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            if tok.letter in ("ن", "م") and tok.has_shadda:
                out.append(_ghunnah_finding(
                    "Ghunnah", i, acoustics,
                    "G‘unna mushaddada: 2 harakat burun tovushi bilan aytildi.",
                ))
        return out


@register
class MeemSakinahRule(Rule):
    """Meem-sakinah: Ikhfa Shafawi (before ب), Idgham Shafawi (before م),
    Izhar Shafawi (everything else)."""

    name = "Meem Sakinah"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            if not (tok.letter == "م" and tok.has_sukun):
                continue
            nxt = _next_letter(tokens, i)
            if nxt is None:
                continue
            n = nxt.letter
            if n == "ب":
                f = _ghunnah_finding(
                    "Ikhfa Shafawi", i, acoustics,
                    "Ixfo shafawiy: mim ‘ba’ oldida g‘unna bilan yashirildi.",
                )
                out.append(f)
            elif n == "م":
                out.append(_ghunnah_finding(
                    "Idgham Shafawi", i, acoustics,
                    "Idg‘om shafawiy: ikki mim g‘unna bilan birlashdi.",
                ))
            else:
                out.append(RuleFinding(
                    "Izhar Shafawi", i, True, "low",
                    "Izhor shafawiy: mim aniq, g‘unnasiz aytiladi.",
                ))
        return out
