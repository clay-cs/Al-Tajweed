"""Pydantic response/request models — the public contract of the service.

These mirror the JSON the Flutter app and Node backend consume. Keeping
them here (and pure) lets the tests import them without pulling in torch.
"""

from __future__ import annotations

from enum import Enum
from typing import Literal, Optional

from pydantic import BaseModel, Field


class LetterStatus(str, Enum):
    correct = "correct"
    incorrect = "incorrect"
    unclear = "unclear"
    missing = "missing"        # expected letter not recited
    extra = "extra"            # recited a letter that isn't expected
    substituted = "substituted"  # wrong but confusable letter recited


class Severity(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class LetterResult(BaseModel):
    index: int = Field(..., description="Position in the expected verse")
    letter: str = Field(..., description="Expected Arabic letter")
    heard: Optional[str] = Field(
        None, description="What the acoustic model actually heard"
    )
    status: LetterStatus
    rule: Optional[str] = Field(
        None, description="Tajweed rule attached to this letter, if any"
    )
    confidence: float = Field(..., ge=0, le=1)
    start: Optional[float] = Field(None, description="Start time (s)")
    end: Optional[float] = Field(None, description="End time (s)")
    feedback: Optional[str] = None


class TajweedError(BaseModel):
    rule: str
    severity: Severity
    letter_index: Optional[int] = None
    start: Optional[float] = None
    end: Optional[float] = None
    expected: Optional[str] = Field(
        None, description="What the rule requires (e.g. '≥2 harakah ghunnah')"
    )
    observed: Optional[str] = Field(
        None, description="What was measured (e.g. '0.7 harakah')"
    )
    feedback: str


class WordResult(BaseModel):
    index: int
    expected: str
    heard: Optional[str] = None
    status: Literal["correct", "incorrect", "substituted", "missing", "extra"]
    start: Optional[float] = None
    end: Optional[float] = None
    confidence: float = Field(..., ge=0, le=1)


class Timing(BaseModel):
    audio_seconds: float
    speech_seconds: float
    words_per_minute: Optional[float] = None


class AssessmentResult(BaseModel):
    score: int = Field(..., ge=0, le=100)
    correct: bool
    transcript: str = Field(..., description="What faster-whisper heard")
    reference: str = Field(..., description="Reference verse text (input)")
    confidence: float = Field(..., ge=0, le=1)
    letters: list[LetterResult] = []
    words: list[WordResult] = []
    tajweed_errors: list[TajweedError] = []
    timing: Timing
    feedback: list[str] = Field(
        default_factory=list, description="Human-readable summary lines"
    )
    engine: str = Field("unavailable", description="Which backend produced this")


class HealthResponse(BaseModel):
    status: str
    device: str
    models_loaded: bool
    whisper_model: str
    w2v_model: str
