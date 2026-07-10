"""ASR + acoustic phoneme layer.

Two models, loaded lazily and cached as singletons:

  1. faster-whisper — word-level transcription + timestamps. Robust ASR
     that gives us *what was recited* and rough word timing. We do NOT
     trust it for letter-level judgement (hence model #2).

  2. Wav2Vec2 CTC with an Arabic character vocabulary — the pronunciation
     engine. Its per-frame character posteriors let us:
       * force-align reference letters to audio (CTC segmentation),
       * compute Goodness-of-Pronunciation (GOP) per letter,
       * detect confusable substitutions (which letter actually won),
       * measure nasal/vowel continuation length (ghunnah/madd harakah),
       * derive heaviness (tafkhim) and burst (qalqalah) proxies.

Why these models:
  * faster-whisper (CTranslate2) is 4× faster / lower-memory than vanilla
    Whisper with int8, and has excellent Arabic coverage. For maximum
    Quran accuracy point WHISPER_MODEL at a ct2-converted
    tarteel-ai/whisper-*-ar-quran checkpoint.
  * Wav2Vec2-XLSR-53-Arabic emits *characters*, which is exactly the unit
    Tajweed reasons about — unlike Whisper's BPE subwords. CTC alignment
    over characters is the standard, well-understood way to get robust
    letter timings and GOP without a separate aligner model.

Everything here degrades gracefully: if a model can't be loaded the
functions raise `ModelsUnavailable`, and the API returns a clear 503.
"""

from __future__ import annotations

import threading
from dataclasses import dataclass
from functools import lru_cache

import numpy as np

from .arabic import letters_only
from .config import settings


class ModelsUnavailable(RuntimeError):
    """Raised when the ML stack can't be loaded (missing deps / weights)."""


_lock = threading.Lock()


# ── faster-whisper ──────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def _whisper():
    try:
        from faster_whisper import WhisperModel
    except Exception as e:  # pragma: no cover
        raise ModelsUnavailable(f"faster-whisper not installed: {e}")
    return WhisperModel(
        settings.whisper_model,
        device=settings.device,
        compute_type=settings.whisper_compute,
    )


@dataclass
class Word:
    text: str
    start: float
    end: float
    prob: float


@dataclass
class Transcription:
    text: str
    words: list[Word]
    language: str


def transcribe(wav: np.ndarray) -> Transcription:
    model = _whisper()
    segments, info = model.transcribe(
        wav,
        language="ar",
        word_timestamps=True,
        vad_filter=False,           # we run our own VAD upstream
        beam_size=5,
        condition_on_previous_text=False,
    )
    words: list[Word] = []
    texts: list[str] = []
    for seg in segments:
        texts.append(seg.text)
        for w in seg.words or []:
            words.append(
                Word(w.word.strip(), float(w.start), float(w.end),
                     float(getattr(w, "probability", 1.0)))
            )
    return Transcription(
        text="".join(texts).strip(),
        words=words,
        language=getattr(info, "language", "ar"),
    )


# ── Wav2Vec2 CTC (character posteriors) ─────────────────────────────────

@lru_cache(maxsize=1)
def _w2v():
    try:
        import torch
        from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
    except Exception as e:  # pragma: no cover
        raise ModelsUnavailable(f"transformers/torch not installed: {e}")
    processor = Wav2Vec2Processor.from_pretrained(settings.w2v_model)
    model = Wav2Vec2ForCTC.from_pretrained(settings.w2v_model)
    model.eval()
    if settings.device == "cuda":
        model = model.to("cuda")
    return processor, model, torch


@dataclass
class CharPosteriors:
    """Per-frame log-probabilities over the model's character vocabulary."""

    logprobs: np.ndarray            # (T, V)
    vocab: dict[str, int]           # char → id
    id2char: dict[int, str]
    frame_seconds: float            # seconds per frame
    blank_id: int


def char_posteriors(wav: np.ndarray) -> CharPosteriors:
    processor, model, torch = _w2v()
    inputs = processor(
        wav, sampling_rate=settings.sample_rate, return_tensors="pt"
    )
    input_values = inputs.input_values
    if settings.device == "cuda":
        input_values = input_values.to("cuda")
    with torch.no_grad():
        logits = model(input_values).logits[0]  # (T, V)
        logprobs = torch.log_softmax(logits, dim=-1).cpu().numpy()
    vocab = processor.tokenizer.get_vocab()   # token → id
    id2char = {v: k for k, v in vocab.items()}
    frame_seconds = len(wav) / settings.sample_rate / logprobs.shape[0]
    blank_id = processor.tokenizer.pad_token_id or 0
    return CharPosteriors(
        logprobs=logprobs,
        vocab=vocab,
        id2char=id2char,
        frame_seconds=frame_seconds,
        blank_id=blank_id,
    )


def models_ready() -> bool:
    """Best-effort check without forcing a heavy download at import time."""
    try:
        import faster_whisper  # noqa: F401
        import torch  # noqa: F401
        import transformers  # noqa: F401

        return True
    except Exception:
        return False
