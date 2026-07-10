"""Central configuration for the Tajweed AI service.

Everything is overridable via environment variables so the same image can
run on CPU (default) or GPU, with small or large models.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field


def _detect_device() -> str:
    """auto → cuda if available, else cpu. Never crashes without torch/CUDA."""
    requested = os.getenv("DEVICE", "auto").lower()
    if requested in ("cpu", "cuda"):
        return requested
    try:
        import torch

        return "cuda" if torch.cuda.is_available() else "cpu"
    except Exception:  # torch missing during docs builds etc.
        return "cpu"


@dataclass(frozen=True)
class Settings:
    # ── Models ──────────────────────────────────────────────────────────
    # faster-whisper: robust ASR for word-level transcription/timestamps.
    # Any CTranslate2 model name or local path works. For Quran-specific
    # accuracy convert tarteel-ai/whisper-base-ar-quran with ct2 and point
    # WHISPER_MODEL at the folder.
    whisper_model: str = os.getenv("WHISPER_MODEL", "small")
    whisper_compute: str = os.getenv(
        "WHISPER_COMPUTE",  # int8 on CPU, float16 on GPU by default
        "float16" if _detect_device() == "cuda" else "int8",
    )

    # Wav2Vec2 CTC model with an Arabic *character* vocabulary — the core
    # of letter-level alignment, GOP scoring and confusion detection.
    w2v_model: str = os.getenv(
        "W2V_MODEL", "jonatasgrosman/wav2vec2-large-xlsr-53-arabic"
    )

    device: str = field(default_factory=_detect_device)

    # ── Audio ───────────────────────────────────────────────────────────
    sample_rate: int = int(os.getenv("SAMPLE_RATE", "16000"))
    max_audio_seconds: float = float(os.getenv("MAX_AUDIO_SECONDS", "120"))
    noise_reduction: bool = os.getenv("NOISE_REDUCTION", "1") == "1"

    # ── Assessment thresholds ───────────────────────────────────────────
    # Letter GOP below this → "incorrect"; between → "unclear".
    gop_incorrect: float = float(os.getenv("GOP_INCORRECT", "0.20"))
    gop_unclear: float = float(os.getenv("GOP_UNCLEAR", "0.45"))
    # A confusable letter must beat the expected letter's posterior by
    # this factor before we call it a substitution.
    confusion_margin: float = float(os.getenv("CONFUSION_MARGIN", "1.6"))

    # ── Server ──────────────────────────────────────────────────────────
    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = int(os.getenv("PORT", "8001"))


settings = Settings()
