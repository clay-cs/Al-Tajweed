"""Unit tests for the confusable-aware letter aligner."""

from app.align import align_letters, alignment_accuracy


def test_perfect_match():
    ref = list("بسم")
    ops = align_letters(ref, ref)
    assert all(o.op == "match" for o in ops)
    assert alignment_accuracy(ops) == 1.0


def test_missing_letter_is_delete():
    ops = align_letters(list("بسم"), list("بم"))
    assert any(o.op == "delete" and o.ref == "س" for o in ops)


def test_extra_letter_is_insert():
    ops = align_letters(list("بم"), list("بسم"))
    assert any(o.op == "insert" and o.hyp == "س" for o in ops)


def test_confusable_substitution_preferred():
    # ض read as ظ should be a single 'confuse' op, not delete+insert.
    ops = align_letters(list("ضرب"), list("ظرب"))
    kinds = [o.op for o in ops]
    assert "confuse" in kinds
    assert "delete" not in kinds and "insert" not in kinds


def test_random_substitution_is_sub():
    ops = align_letters(list("بسم"), list("بنم"))
    assert any(o.op == "sub" for o in ops)


def test_accuracy_partial():
    ops = align_letters(list("بسم"), list("بشم"))  # س→ش not confusable pair
    assert 0.0 < alignment_accuracy(ops) < 1.0
