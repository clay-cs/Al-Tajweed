"""Audio preprocessing: decode → resample → mono → VAD → noise reduction.

Heavy deps (soundfile, librosa, torch, noisereduce, silero) are imported
lazily so the pure modules and their tests never pull them in. Every step
degrades gracefully if an optional dependency is missing.
"""

from __future__ import annotations

import io
from dataclasses import dataclass

import numpy as np

from .config import settings


@dataclass
class ProcessedAudio:
    samples: np.ndarray            # float32 mono, in [-1, 1]
    sample_rate: int
    duration: float                # seconds (full clip)
    speech_segments: list[tuple[float, float]]  # (start,end) seconds
    speech_seconds: float


def load_audio(data: bytes) -> tuple[np.ndarray, int]:
    """Decode arbitrary audio bytes to float32 mono at the target rate."""
    import soundfile as sf  # lazy

    try:
        wav, sr = sf.read(io.BytesIO(data), dtype="float32", always_2d=False)
    except Exception:
        # Fall back to librosa/audioread for formats soundfile can't open
        # (e.g. m4a/aac from mobile).
        import librosa

        wav, sr = librosa.load(
            io.BytesIO(data), sr=settings.sample_rate, mono=True
        )
        return wav.astype(np.float32), sr

    if wav.ndim > 1:  # stereo → mono
        wav = wav.mean(axis=1)
    if sr != settings.sample_rate:
        import librosa

        wav = librosa.resample(
            wav, orig_sr=sr, target_sr=settings.sample_rate
        )
        sr = settings.sample_rate
    return wav.astype(np.float32), sr


def reduce_noise(wav: np.ndarray, sr: int) -> np.ndarray:
    if not settings.noise_reduction:
        return wav
    try:
        import noisereduce as nr

        return nr.reduce_noise(y=wav, sr=sr, stationary=False).astype(
            np.float32
        )
    except Exception:
        return wav


def _energy_vad(wav: np.ndarray, sr: int) -> list[tuple[float, float]]:
    """Fallback VAD: frame energy above an adaptive floor = speech."""
    frame = int(0.03 * sr)
    if frame == 0 or len(wav) < frame:
        return [(0.0, len(wav) / sr)] if len(wav) else []
    n = len(wav) // frame
    energies = np.array(
        [np.sqrt(np.mean(wav[i * frame:(i + 1) * frame] ** 2)) for i in range(n)]
    )
    if energies.max() <= 0:
        return []
    thresh = max(energies.mean() * 0.5, energies.max() * 0.08)
    voiced = energies > thresh
    segs: list[tuple[float, float]] = []
    start = None
    for i, v in enumerate(voiced):
        t = i * frame / sr
        if v and start is None:
            start = t
        elif not v and start is not None:
            segs.append((start, t))
            start = None
    if start is not None:
        segs.append((start, n * frame / sr))
    return segs


def detect_speech(wav: np.ndarray, sr: int) -> list[tuple[float, float]]:
    """Silero VAD when available, else energy-based fallback."""
    try:
        import torch

        model, utils = torch.hub.load(
            repo_or_dir="snakers4/silero-vad",
            model="silero_vad",
            trust_repo=True,
            onnx=False,
        )
        (get_speech_timestamps, _, _, _, _) = utils
        ts = get_speech_timestamps(
            torch.from_numpy(wav), model, sampling_rate=sr
        )
        return [(t["start"] / sr, t["end"] / sr) for t in ts]
    except Exception:
        return _energy_vad(wav, sr)


def preprocess(data: bytes) -> ProcessedAudio:
    wav, sr = load_audio(data)
    duration = len(wav) / sr if sr else 0.0
    if duration > settings.max_audio_seconds:
        wav = wav[: int(settings.max_audio_seconds * sr)]
        duration = settings.max_audio_seconds
    # Peak-normalise before denoise for stable thresholds.
    peak = float(np.max(np.abs(wav))) if len(wav) else 0.0
    if peak > 0:
        wav = wav / peak * 0.95
    wav = reduce_noise(wav, sr)
    segments = detect_speech(wav, sr)
    speech_seconds = sum(e - s for s, e in segments)
    return ProcessedAudio(
        samples=wav,
        sample_rate=sr,
        duration=duration,
        speech_segments=segments,
        speech_seconds=speech_seconds,
    )
