"""Unit tests for the final scoring blend."""

from app.align import align_letters
from app.scoring import compute_score
from app.tajweed.engine import RuleFinding


def _ok(rule):
    return RuleFinding(rule, 0, True, "low", "ok")


def _fail(rule, sev="high"):
    return RuleFinding(rule, 0, False, sev, "bad")


def test_perfect_recitation_scores_high():
    ref = list("الحمد")
    ops = align_letters(ref, ref)
    b = compute_score(ops, [_ok("Ghunnah")], mean_gop=0.95)
    assert b.score >= 95
    assert b.correct


def test_missing_letters_lower_score():
    ops = align_letters(list("الحمد"), list("احد"))
    b = compute_score(ops, [], mean_gop=0.9)
    assert b.score < 90
    assert not b.correct


def test_high_severity_tajweed_breaks_correct():
    ref = list("منم")
    ops = align_letters(ref, ref)
    b = compute_score(ops, [_fail("Ikhfa", "high")], mean_gop=0.9)
    assert not b.correct           # high-severity failure blocks "correct"
    assert b.score < 100


def test_score_bounded():
    ops = align_letters(list("ا"), list("ب"))
    b = compute_score(ops, [_fail("Madd")], mean_gop=0.0)
    assert 0 <= b.score <= 100
