"""Arabic text normalization + Tajweed-relevant phonetic knowledge.

Pure Python, no ML dependencies — this is the linguistic backbone the rest
of the pipeline builds on and the part that is unit-tested in isolation.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

# ── Character classes ───────────────────────────────────────────────────

# Harakat / tanwin / shadda / sukun / superscript alef and quranic marks.
DIACRITICS = (
    "ؘؙؚؐؑؒؓؔؕؖؗ"
    "ًٌٍَُِّْٕٓٔ"
    "ٰٖٗ٘ۖۗۘۙۚۛۜ"
    "ۣ۟۠ۡۢۤۥۦ۪ۧۨ"
    "ۭ۫۬"
)
DIACRITIC_RE = re.compile(f"[{DIACRITICS}]")
TATWEEL = "ـ"

FATHA = "َ"
DAMMA = "ُ"
KASRA = "ِ"
SUKUN = "ْ"
SHADDA = "ّ"
FATHATAN = "ً"
DAMMATAN = "ٌ"
KASRATAN = "ٍ"
SUPERSCRIPT_ALEF = "ٰ"
TANWIN = {FATHATAN, DAMMATAN, KASRATAN}
SHORT_VOWELS = {FATHA, DAMMA, KASRA}

ALEF_VARIANTS = "آأإاٱ"  # آ أ إ ا ٱ
ALEF = "ا"

# Letters after which noon-sakinah / tanwin rules fire.
THROAT_LETTERS = set("ءأإآهعحغخ")          # izhar halqi
IKHFA_LETTERS = set("تثجدذزسشصضطظفقك")      # ikhfa haqiqi
IDGHAM_GHUNNAH = set("يومن")                # يرملون minus ل ر
IDGHAM_NO_GHUNNAH = set("لر")
IQLAB_LETTER = "ب"

QALQALAH_LETTERS = set("قطبجد")             # قطب جد
# Heavy (mufakhkham) letters — always tafkhim.
ISTILA_LETTERS = set("خصضغطقظ")             # خص ضغط قظ
SUN_LETTERS = set("تثدذرزسشصضطظلن")          # lam shamsiyyah
MOON_LETTERS = set("ابجحخعغفقكمهوي")         # lam qamariyyah

# Madd letters (long-vowel carriers).
MADD_LETTERS = {ALEF, "و", "ي"}    # ا و ي
HAMZA = set("ءأإؤئآ")

# ── Confusable pairs (makharij / sifaat neighbours) ─────────────────────
# Ordered pairs → both directions are registered. Used to decide whether a
# mismatch is a plausible substitution vs a random miss.
CONFUSABLE_PAIRS = [
    ("ض", "ظ"),
    ("ص", "س"),
    ("ذ", "ز"),
    ("ق", "ك"),
    ("ط", "ت"),
    ("ح", "ه"),
    ("ع", "ا"),
    ("ع", "ء"),
    ("ث", "س"),
    ("ذ", "ظ"),
    ("د", "ت"),
    ("ه", "ح"),
    ("س", "ص"),
    ("ز", "ذ"),
    ("ك", "ق"),
    ("غ", "خ"),
    ("ا", "أ"),
]

_CONFUSABLE: dict[str, set[str]] = {}
for _a, _b in CONFUSABLE_PAIRS:
    _CONFUSABLE.setdefault(_a, set()).add(_b)
    _CONFUSABLE.setdefault(_b, set()).add(_a)


def are_confusable(a: str, b: str) -> bool:
    """True if a and b are a known makharij/sifaat-neighbour pair."""
    return b in _CONFUSABLE.get(a, ())


def confusables_of(letter: str) -> set[str]:
    return set(_CONFUSABLE.get(letter, ()))


# ── Normalization ───────────────────────────────────────────────────────

def strip_diacritics(text: str) -> str:
    return DIACRITIC_RE.sub("", text).replace(TATWEEL, "")


def normalize_alef(text: str) -> str:
    for v in ALEF_VARIANTS:
        text = text.replace(v, ALEF)
    return text


def normalize_for_compare(text: str) -> str:
    """Canonical, diacritic-free form for word/letter matching."""
    text = unicodedata.normalize("NFC", text)
    text = strip_diacritics(text)
    text = normalize_alef(text)
    text = text.replace("ى", "ي")  # alef maqsura → ya
    text = text.replace("ة", "ه")  # ta marbuta → ha
    text = re.sub(r"\s+", " ", text).strip()
    return text


def letters_only(text: str) -> list[str]:
    """Base consonant/long-vowel letters, diacritics removed, no spaces."""
    norm = normalize_for_compare(text)
    return [c for c in norm if not c.isspace()]


def words(text: str) -> list[str]:
    return [w for w in normalize_for_compare(text).split(" ") if w]


# ── Diacritic-aware token model ─────────────────────────────────────────

@dataclass
class Token:
    """A base letter plus the harakat attached to it, with its char index."""

    letter: str
    harakat: str  # concatenated combining marks (may be empty)
    index: int    # position in the diacritic-free letter sequence

    @property
    def has_sukun(self) -> bool:
        return SUKUN in self.harakat or (
            not self.harakat and self.letter not in MADD_LETTERS
        )

    @property
    def has_shadda(self) -> bool:
        return SHADDA in self.harakat

    @property
    def tanwin(self) -> str | None:
        for t in TANWIN:
            if t in self.harakat:
                return t
        return None

    @property
    def vowel(self) -> str | None:
        for v in SHORT_VOWELS:
            if v in self.harakat:
                return v
        return None


def tokenize(text: str) -> list[Token]:
    """Split fully-vocalised text into (letter, attached-harakat) tokens.

    Alef variants are normalised but the ORIGINAL diacritics are preserved
    so the rule engine can read sukun/shadda/tanwin.
    """
    text = unicodedata.normalize("NFC", text)
    tokens: list[Token] = []
    idx = -1
    for ch in text:
        if DIACRITIC_RE.match(ch):
            if tokens:
                tokens[-1].harakat += ch
            continue
        if ch.isspace() or ch == TATWEEL:
            continue
        base = ch
        if base in ALEF_VARIANTS:
            base = ALEF
        idx += 1
        tokens.append(Token(letter=base, harakat="", index=idx))
    return tokens
