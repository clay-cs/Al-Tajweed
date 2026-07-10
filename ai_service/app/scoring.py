"""Final scoring: turn alignment + tajweed findings into a 0-100 score.

Deterministic and pure so it is unit-tested directly. The score blends:
  * letter accuracy (how much of the verse was recited correctly)
  * tajweed penalty (weighted by severity of *failed* rules)
  * pronunciation confidence (mean GOP of recited letters)
"""

from __future__ import annotations

from dataclasses import dataclass

from .align import AlignOp
from .tajweed import RuleFinding

SEVERITY_WEIGHT = {"low": 1.0, "medium": 3.0, "high": 6.0}

# How much each component contributes.
W_ACCURACY = 0.6
W_TAJWEED = 0.3
W_CONFIDENCE = 0.1


@dataclass
class ScoreBreakdown:
    score: int
    accuracy: float
    tajweed: float
    confidence: float
    correct: bool


def _accuracy(ops: list[AlignOp]) -> float:
    ref_total = sum(1 for o in ops if o.ref_index is not None)
    if ref_total == 0:
        return 0.0
    # match = 1, confuse = 0.3 credit, sub/delete = 0. Extra insertions
    # apply a small flat penalty below.
    credit = 0.0
    for o in ops:
        if o.op == "match":
            credit += 1.0
        elif o.op == "confuse":
            credit += 0.3
    inserts = sum(1 for o in ops if o.op == "insert")
    acc = (credit - 0.5 * inserts) / ref_total
    return max(0.0, min(1.0, acc))


def _tajweed_score(findings: list[RuleFinding]) -> float:
    """1.0 = flawless tajweed. Each failed rule subtracts weighted penalty,
    normalised by the number of *applicable* rules so a long verse isn't
    unfairly punished."""
    applicable = [f for f in findings if f.severity is not None]
    if not applicable:
        return 1.0
    failed = [f for f in findings if not f.applied]
    penalty = sum(SEVERITY_WEIGHT.get(f.severity, 1.0) for f in failed)
    max_penalty = sum(
        SEVERITY_WEIGHT.get("high", 6.0) for _ in applicable
    )
    if max_penalty == 0:
        return 1.0
    return max(0.0, 1.0 - penalty / max_penalty)


def compute_score(
    ops: list[AlignOp],
    findings: list[RuleFinding],
    mean_gop: float,
) -> ScoreBreakdown:
    accuracy = _accuracy(ops)
    tajweed = _tajweed_score(findings)
    confidence = max(0.0, min(1.0, mean_gop))
    raw = (
        W_ACCURACY * accuracy
        + W_TAJWEED * tajweed
        + W_CONFIDENCE * confidence
    )
    score = int(round(raw * 100))
    # "correct" = recited essentially the right verse with no high-severity
    # tajweed failures.
    no_high = not any(not f.applied and f.severity == "high" for f in findings)
    correct = accuracy >= 0.9 and no_high
    return ScoreBreakdown(
        score=score,
        accuracy=accuracy,
        tajweed=tajweed,
        confidence=confidence,
        correct=correct,
    )
