"""The rule engine core: data model, base class, registry and driver.

Rules are intentionally decoupled from the ML layer. They receive:
  * `tokens`  — vocalised reference letters (with harakat), from arabic.tokenize
  * `acoustics` — per-letter acoustic observations (durations, timings,
                  formant/pitch proxies) that the aligner produced.

A rule that has no acoustic signal to check still fires *positionally*
(e.g. "there IS an ikhfa here") and reports whether it was applied,
degrading gracefully to a neutral finding when audio evidence is absent.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Optional

from ..arabic import Token


@dataclass
class LetterAcoustic:
    """Acoustic measurement for one reference letter (post-alignment)."""

    index: int
    start: Optional[float] = None
    end: Optional[float] = None
    recited: bool = True            # was this letter actually voiced?
    heard: Optional[str] = None     # letter the acoustic model decoded
    gop: float = 1.0                # goodness-of-pronunciation ∈ [0,1]
    # Duration of the *voiced continuation* on this letter, in harakah
    # units (1 harakah ≈ one short-vowel beat). Used for ghunnah/madd.
    harakah: float = 0.0
    # Heaviness proxy ∈ [0,1]: high → dark/mufakhkham, low → light/muraqqaq.
    heaviness: Optional[float] = None
    # Energy burst proxy ∈ [0,1] for qalqalah "bounce".
    bounce: Optional[float] = None


@dataclass
class Acoustics:
    """Everything the rules need from the audio side, per reference letter."""

    letters: list[LetterAcoustic]
    # Global timing of detected speech segments (start,end) in seconds.
    speech_segments: list[tuple[float, float]] = field(default_factory=list)

    def by_index(self, i: int) -> Optional[LetterAcoustic]:
        for la in self.letters:
            if la.index == i:
                return la
        return None


@dataclass
class RuleFinding:
    rule: str
    letter_index: Optional[int]
    applied: bool                 # was the rule executed correctly?
    severity: str                 # low | medium | high (only if not applied)
    feedback: str
    expected: Optional[str] = None
    observed: Optional[str] = None
    start: Optional[float] = None
    end: Optional[float] = None


class Rule:
    """Base class. Subclasses implement `check`."""

    name: str = "Rule"

    def check(
        self, tokens: list[Token], acoustics: Acoustics
    ) -> list[RuleFinding]:  # pragma: no cover - interface
        raise NotImplementedError


RULES: list[Rule] = []


def register(rule_cls: type[Rule]) -> type[Rule]:
    """Class decorator that adds a rule instance to the global registry."""
    RULES.append(rule_cls())
    return rule_cls


def analyze(tokens: list[Token], acoustics: Acoustics) -> list[RuleFinding]:
    """Run every registered rule and collect findings."""
    findings: list[RuleFinding] = []
    for rule in RULES:
        try:
            findings.extend(rule.check(tokens, acoustics))
        except Exception:  # a broken rule must never take the request down
            continue
    findings.sort(key=lambda f: (f.letter_index is None, f.letter_index or 0))
    return findings


# Import rule modules for their side effect (registration). Kept at the
# bottom so `register`/`Rule` are defined first.
from . import rules_noon_meem  # noqa: E402,F401
from . import rules_madd       # noqa: E402,F401
from . import rules_letters    # noqa: E402,F401
