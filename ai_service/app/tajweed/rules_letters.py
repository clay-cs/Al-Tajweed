"""Letter-level Tajweed: Qalqalah, Tafkhim/Tarqiq, Lam Shamsiyyah/Qamariyyah,
and Makharij/Sifaat (articulation) mistakes via the acoustic GOP + confusion.

These are the rules that turn per-letter acoustic evidence into concrete,
letter-anchored feedback.
"""

from __future__ import annotations

from ..arabic import (
    ISTILA_LETTERS,
    MOON_LETTERS,
    QALQALAH_LETTERS,
    SUN_LETTERS,
    are_confusable,
)
from .engine import Acoustics, RuleFinding, Rule, register

# Heaviness proxy above → dark (tafkhim); below → light (tarqiq).
HEAVY_THRESHOLD = 0.55
BOUNCE_THRESHOLD = 0.45     # qalqalah "echo" energy proxy
GOP_MISPRONOUNCED = 0.35    # below → makharij/sifaat mistake


@register
class QalqalahRule(Rule):
    """قطب جد letters carrying sukun bounce. We reward a detected bounce
    and flag its absence."""

    name = "Qalqalah"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            if tok.letter in QALQALAH_LETTERS and tok.has_sukun:
                la = acoustics.by_index(i)
                if la is None or la.bounce is None:
                    out.append(RuleFinding(
                        "Qalqalah", i, True, "low",
                        "Qalqala harfi — sokin holatda ‘sakrash’ (echo) "
                        "bilan aytiladi.",
                    ))
                elif la.bounce >= BOUNCE_THRESHOLD:
                    out.append(RuleFinding(
                        "Qalqalah", i, True, "low",
                        "Qalqala to‘g‘ri — aniq sakrash eshitildi.",
                        start=la.start, end=la.end,
                    ))
                else:
                    out.append(RuleFinding(
                        "Qalqalah", i, False, "medium",
                        "Qalqala sust — harfni aniqroq ‘sakratib’ ayting.",
                        start=la.start, end=la.end,
                    ))
        return out


@register
class TafkhimTarqiqRule(Rule):
    """Istila letters must be heavy (tafkhim); others (ra/lam context aside)
    light. We check the heaviness proxy against the expected class."""

    name = "Tafkhim"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            heavy_expected = tok.letter in ISTILA_LETTERS
            la = acoustics.by_index(i)
            if la is None or la.heaviness is None:
                continue
            if heavy_expected:
                if la.heaviness >= HEAVY_THRESHOLD:
                    out.append(RuleFinding(
                        "Tafkhim", i, True, "low",
                        "Tafxim: harf to‘g‘ri yo‘g‘on (og‘ir) aytildi.",
                        start=la.start, end=la.end,
                    ))
                else:
                    out.append(RuleFinding(
                        "Tafkhim", i, False, "medium",
                        "Tafxim yetishmadi — bu harf yo‘g‘on aytilishi kerak.",
                        start=la.start, end=la.end,
                    ))
            else:
                # Only flag over-heaviness on clearly light letters.
                if la.heaviness > HEAVY_THRESHOLD + 0.25:
                    out.append(RuleFinding(
                        "Tarqiq", i, False, "low",
                        "Tarqiq: bu harf ingichka (yengil) aytilishi kerak.",
                        start=la.start, end=la.end,
                    ))
        return out


@register
class LamRule(Rule):
    """Definite article ال: lam is silent+assimilated before sun letters
    (shamsiyyah), pronounced before moon letters (qamariyyah)."""

    name = "Lam"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i in range(len(tokens) - 1):
            if tokens[i].letter == "ا" and tokens[i + 1].letter == "ل":
                if i + 2 >= len(tokens):
                    continue
                after = tokens[i + 2].letter
                if after in SUN_LETTERS:
                    out.append(RuleFinding(
                        "Lam Shamsiyyah", i + 1, True, "low",
                        "Lom shamsiyya: ‘lom’ aytilmaydi, keyingi harf "
                        "shaddalanadi.",
                    ))
                elif after in MOON_LETTERS:
                    out.append(RuleFinding(
                        "Lam Qamariyyah", i + 1, True, "low",
                        "Lom qamariyya: ‘lom’ aniq talaffuz qilinadi.",
                    ))
        return out


@register
class MakharijSifaatRule(Rule):
    """Articulation-point / attribute mistakes: a low GOP on a letter, or a
    decoded neighbour from a confusable pair, is a makharij/sifaat error."""

    name = "Makharij"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            la = acoustics.by_index(i)
            if la is None or not la.recited:
                continue
            heard = la.heard
            if heard and heard != tok.letter and are_confusable(tok.letter, heard):
                out.append(RuleFinding(
                    "Sifaat", i, False, "high",
                    f"Harf almashinuvi: ‘{tok.letter}’ o‘rniga ‘{heard}’ "
                    "eshitildi — maxrajga e’tibor bering.",
                    expected=tok.letter, observed=heard,
                    start=la.start, end=la.end,
                ))
            elif la.gop < GOP_MISPRONOUNCED:
                out.append(RuleFinding(
                    "Makharij", i, False, "medium",
                    f"‘{tok.letter}’ harfi noaniq talaffuz qilindi — "
                    "chiqish o‘rnini (maxraj) to‘g‘rilang.",
                    expected=tok.letter, observed=heard,
                    start=la.start, end=la.end,
                ))
        return out
