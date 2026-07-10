"""Extensible Tajweed rule engine.

Each rule is a small class implementing `Rule`. `analyze()` runs every
registered rule over the vocalised reference tokens plus the acoustic
observations and returns the union of their findings. Add a rule by
writing a class and appending it to RULES — nothing else changes.
"""

from .engine import RULES, Acoustics, RuleFinding, analyze, register

__all__ = ["RULES", "Acoustics", "RuleFinding", "analyze", "register"]
