"""Unit tests for the Tajweed rule engine using synthetic acoustics."""

from app import arabic
from app.tajweed import analyze
from app.tajweed.engine import Acoustics, LetterAcoustic


def _acoustics_for(tokens, harakah=2.0, gop=0.9, bounce=0.6, heaviness=0.8):
    """Build 'perfect' acoustics for every reference letter."""
    return Acoustics(letters=[
        LetterAcoustic(
            index=t.index, start=t.index * 0.2, end=t.index * 0.2 + 0.18,
            recited=True, heard=t.letter, gop=gop, harakah=harakah,
            heaviness=heaviness if t.letter in arabic.ISTILA_LETTERS else 0.3,
            bounce=bounce,
        )
        for t in tokens
    ])


def _rules(findings):
    return {f.rule for f in findings}


def test_ikhfa_detected_positionally():
    # نْ followed by ت → ikhfa
    tokens = arabic.tokenize("مِنْتَ")
    findings = analyze(tokens, _acoustics_for(tokens))
    assert "Ikhfa" in _rules(findings)


def test_izhar_detected():
    # نْ followed by ء/ه/ع… → izhar. Use نْ + ح.
    tokens = arabic.tokenize("مِنْحَ")
    findings = analyze(tokens, _acoustics_for(tokens))
    assert "Izhar" in _rules(findings)


def test_iqlab_detected():
    tokens = arabic.tokenize("مِنْبَ")
    findings = analyze(tokens, _acoustics_for(tokens))
    assert "Iqlab" in _rules(findings)


def test_idgham_ghunnah_detected():
    tokens = arabic.tokenize("مِنْمَ")  # noon + meem → idgham ma'a ghunnah
    findings = analyze(tokens, _acoustics_for(tokens))
    assert "Idgham Ma'a Ghunnah" in _rules(findings)


def test_short_ghunnah_flagged_as_error():
    tokens = arabic.tokenize("مِنْمَ")
    # harakah far below the 1.4 threshold → rule should fail
    ac = _acoustics_for(tokens, harakah=0.3)
    findings = analyze(tokens, ac)
    idgham = [f for f in findings if f.rule == "Idgham Ma'a Ghunnah"][0]
    assert idgham.applied is False
    assert idgham.severity in ("medium", "high")


def test_madd_detected_and_scored():
    tokens = arabic.tokenize("قَالَ")  # alef madd
    findings = analyze(tokens, _acoustics_for(tokens, harakah=2.0))
    madd = [f for f in findings if f.rule.startswith("Madd")]
    assert madd and madd[0].applied


def test_madd_too_short_flagged():
    tokens = arabic.tokenize("قَالَ")
    findings = analyze(tokens, _acoustics_for(tokens, harakah=0.4))
    madd = [f for f in findings if f.rule.startswith("Madd")]
    assert madd and not madd[0].applied


def test_qalqalah_detected():
    tokens = arabic.tokenize("أَحَدْ")  # dal with sukun at stop
    findings = analyze(tokens, _acoustics_for(tokens, bounce=0.7))
    assert "Qalqalah" in _rules(findings)


def test_qalqalah_weak_flagged():
    tokens = arabic.tokenize("أَحَدْ")
    findings = analyze(tokens, _acoustics_for(tokens, bounce=0.1))
    q = [f for f in findings if f.rule == "Qalqalah"][0]
    assert not q.applied


def test_lam_shamsiyyah_detected():
    tokens = arabic.tokenize("الشَّمْس")  # ال + ش (sun letter)
    findings = analyze(tokens, _acoustics_for(tokens))
    assert "Lam Shamsiyyah" in _rules(findings)


def test_lam_qamariyyah_detected():
    tokens = arabic.tokenize("القَمَر")  # ال + ق (moon letter)
    findings = analyze(tokens, _acoustics_for(tokens))
    assert "Lam Qamariyyah" in _rules(findings)


def test_makharij_substitution_flagged():
    tokens = arabic.tokenize("ضَرَبَ")
    ac = _acoustics_for(tokens)
    # Make the ض be heard as ظ (a confusable) → sifaat error
    for la in ac.letters:
        if tokens[la.index].letter == "ض":
            la.heard = "ظ"
    findings = analyze(tokens, ac)
    assert "Sifaat" in _rules(findings)
