"""Sequence alignment between reference letters and what was recited.

A weighted edit-distance (Needleman–Wunsch/Levenshtein backtrace) whose
substitution cost is *lower* for confusable letter pairs, so the aligner
prefers to call ض→ظ a substitution rather than a delete+insert. This is
what gives us letter-level missing / extra / wrong / substituted labels.

Pure Python — no ML deps — so it is unit-tested directly.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from .arabic import are_confusable

Op = Literal["match", "sub", "confuse", "delete", "insert"]

# Costs (lower = more likely to be chosen by the aligner).
_MATCH = 0.0
_CONFUSE = 0.6   # confusable substitution (ض↔ظ) — cheap
_SUB = 1.0       # arbitrary substitution
_INDEL = 1.0     # insertion / deletion


@dataclass
class AlignOp:
    op: Op
    ref_index: int | None   # index into reference letters (None for insert)
    hyp_index: int | None   # index into heard letters (None for delete)
    ref: str | None
    hyp: str | None


def _sub_cost(a: str, b: str) -> tuple[float, Op]:
    if a == b:
        return _MATCH, "match"
    if are_confusable(a, b):
        return _CONFUSE, "confuse"
    return _SUB, "sub"


def align_letters(ref: list[str], hyp: list[str]) -> list[AlignOp]:
    """Align reference letters to heard letters with confusable-aware costs.

    Returns the ordered edit script. Ops:
      match   — same letter
      confuse — confusable substitution (likely makharij/sifaat error)
      sub     — unrelated substitution
      delete  — reference letter missing from recitation
      insert  — extra letter recited
    """
    n, m = len(ref), len(hyp)
    # dp[i][j] = best cost aligning ref[:i] with hyp[:j]
    dp = [[0.0] * (m + 1) for _ in range(n + 1)]
    back: list[list[Op | None]] = [[None] * (m + 1) for _ in range(n + 1)]

    for i in range(1, n + 1):
        dp[i][0] = i * _INDEL
        back[i][0] = "delete"
    for j in range(1, m + 1):
        dp[0][j] = j * _INDEL
        back[0][j] = "insert"

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            cost, op = _sub_cost(ref[i - 1], hyp[j - 1])
            diag = dp[i - 1][j - 1] + cost
            up = dp[i - 1][j] + _INDEL      # delete ref[i-1]
            left = dp[i][j - 1] + _INDEL    # insert hyp[j-1]
            best = min(diag, up, left)
            dp[i][j] = best
            if best == diag:
                back[i][j] = op
            elif best == up:
                back[i][j] = "delete"
            else:
                back[i][j] = "insert"

    # Backtrace.
    ops: list[AlignOp] = []
    i, j = n, m
    while i > 0 or j > 0:
        op = back[i][j]
        if op in ("match", "sub", "confuse"):
            ops.append(
                AlignOp(op, i - 1, j - 1, ref[i - 1], hyp[j - 1])
            )
            i, j = i - 1, j - 1
        elif op == "delete":
            ops.append(AlignOp("delete", i - 1, None, ref[i - 1], None))
            i -= 1
        else:  # insert
            ops.append(AlignOp("insert", None, j - 1, None, hyp[j - 1]))
            j -= 1
    ops.reverse()
    return ops


def alignment_accuracy(ops: list[AlignOp]) -> float:
    """Fraction of reference letters recited correctly (match only)."""
    ref_total = sum(1 for o in ops if o.ref_index is not None)
    if ref_total == 0:
        return 0.0
    correct = sum(1 for o in ops if o.op == "match")
    return correct / ref_total
