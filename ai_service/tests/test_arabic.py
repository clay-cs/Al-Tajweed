"""Unit tests for Arabic normalization + phonetic knowledge (no ML deps)."""

from app import arabic


def test_strip_diacritics():
    text = "بِسْمِ اللَّهِ"
    assert arabic.strip_diacritics(text) == "بسم الله"


def test_normalize_alef_variants():
    assert arabic.normalize_for_compare("أإآا") == "اااا"


def test_letters_only_drops_spaces_and_marks():
    letters = arabic.letters_only("الْحَمْدُ لِلَّهِ")
    assert " " not in letters
    assert letters[0] == "ا"


def test_confusable_pairs_symmetric():
    assert arabic.are_confusable("ض", "ظ")
    assert arabic.are_confusable("ظ", "ض")   # both directions
    assert arabic.are_confusable("ص", "س")
    assert not arabic.are_confusable("ب", "ن")


def test_tokenize_reads_sukun_and_shadda():
    toks = arabic.tokenize("أَنْعَمْتَ")
    # noon here carries sukun
    noon = [t for t in toks if t.letter == "ن"][0]
    assert noon.has_sukun
    meem = [t for t in toks if t.letter == "م"][0]
    assert meem.has_sukun


def test_tokenize_tanwin_detected():
    toks = arabic.tokenize("سَمِيعٌ")
    assert any(t.tanwin is not None for t in toks)


def test_sun_and_moon_letters_disjoint():
    assert not (arabic.SUN_LETTERS & arabic.MOON_LETTERS)
