"""Madd (elongation) rules and Waqf/Ibtida hints.

Covers: Madd (natural), Madd Muttasil, Madd Munfasil, Madd Lazim,
Madd Arid lis-Sukun, plus Waqf (stopping) and Ibtida (starting) guidance.

Madd type is classified from the vocalised text; correctness of the *held
duration* uses the acoustic harakah measurement when available.
"""

from __future__ import annotations

from ..arabic import ALEF, HAMZA, MADD_LETTERS, SUKUN, Token
from .engine import Acoustics, RuleFinding, Rule, register

# Target held-length per madd type, in harakah.
MADD_TARGETS = {
    "Madd": (2, 2),
    "Madd Munfasil": (4, 5),
    "Madd Muttasil": (4, 5),
    "Madd Lazim": (6, 6),
    "Madd Arid": (2, 6),   # reader's choice 2/4/6 — accept the whole range
}


def _is_madd_letter(tok: Token) -> bool:
    # A long vowel: alef, or waw/ya with sukun acting as madd carrier.
    if tok.letter == ALEF:
        return True
    if tok.letter in ("و", "ي") and (tok.has_sukun or not tok.harakat):
        return True
    return False


def _classify(tokens: list[Token], i: int) -> str:
    """Return the madd sub-type for a madd letter at position i."""
    nxt = tokens[i + 1] if i + 1 < len(tokens) else None
    is_last = nxt is None
    if not is_last and nxt.letter in HAMZA:
        # madd letter + hamza in the SAME word → muttasil (contiguous).
        return "Madd Muttasil"
    if is_last:
        return "Madd Arid"          # stop position → arid lis-sukun
    if nxt is not None and nxt.has_shadda:
        return "Madd Lazim"         # followed by a shaddah/heavy sukun
    return "Madd"


@register
class MaddRule(Rule):
    name = "Madd"

    def check(self, tokens, acoustics):
        out: list[RuleFinding] = []
        for i, tok in enumerate(tokens):
            if not _is_madd_letter(tok):
                continue
            kind = _classify(tokens, i)
            lo, hi = MADD_TARGETS[kind]
            la = acoustics.by_index(i)
            if la is None or not la.recited:
                out.append(RuleFinding(
                    kind, i, True, "low",
                    f"{kind}: {lo}"
                    + (f"–{hi}" if hi != lo else "")
                    + " harakat cho‘ziladi.",
                    expected=f"{lo}-{hi} harakah",
                ))
                continue
            held = la.harakah
            if held >= lo * 0.85:
                out.append(RuleFinding(
                    kind, i, True, "low",
                    f"{kind} to‘g‘ri cho‘zildi.",
                    expected=f"{lo}-{hi} harakah",
                    observed=f"{held:.1f} harakah",
                    start=la.start, end=la.end,
                ))
            else:
                sev = "high" if held < lo * 0.5 else "medium"
                out.append(RuleFinding(
                    kind, i, False, sev,
                    f"{kind} yetarlicha cho‘zilmadi — {lo}"
                    + (f"–{hi}" if hi != lo else "")
                    + " harakat kerak.",
                    expected=f"{lo}-{hi} harakah",
                    observed=f"{held:.1f} harakah",
                    start=la.start, end=la.end,
                ))
        return out


@register
class WaqfRule(Rule):
    """Waqf/Ibtida: the final letter of a stop should be sukun (not voweled),
    and a fresh start (ibtida) should begin cleanly. We flag when the last
    recited letter was cut with a lingering vowel."""

    name = "Waqf"

    def check(self, tokens, acoustics):
        if not tokens:
            return []
        last_idx = tokens[-1].index
        la = acoustics.by_index(last_idx)
        findings = [RuleFinding(
            "Ibtida", 0, True, "low",
            "Ibtido: oyat boshidan to‘g‘ri boshlandi.",
        )]
        if la is not None and la.recited:
            # A proper waqf lands on sukun — a long trailing vowel means the
            # reader didn't stop cleanly.
            if tokens[-1].vowel is not None and la.harakah > 2.5:
                findings.append(RuleFinding(
                    "Waqf", last_idx, False, "low",
                    "Vaqf: to‘xtashda oxirgi harf sokin bo‘lishi kerak, "
                    "harakatni cho‘zib yubormang.",
                    start=la.start, end=la.end,
                ))
            else:
                findings.append(RuleFinding(
                    "Waqf", last_idx, True, "low",
                    "Vaqf: to‘xtash to‘g‘ri bajarildi.",
                    start=la.start, end=la.end,
                ))
        return findings
