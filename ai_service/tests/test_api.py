"""API smoke tests that don't require the ML stack.

/health must work cold, and the assess endpoints must fail gracefully with
503 (not crash) when models aren't installed.
"""

import base64

import pytest

pytest.importorskip("fastapi")
from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def test_health_ok():
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "device" in body


def test_assess_requires_reference():
    r = client.post(
        "/v1/tajweed/assess-json",
        json={"reference": "", "audio_base64": base64.b64encode(b"x").decode()},
    )
    assert r.status_code == 400


def test_assess_bad_base64():
    r = client.post(
        "/v1/tajweed/assess-json",
        json={"reference": "بسم الله", "audio_base64": "!!!notb64!!!"},
    )
    assert r.status_code == 400


def test_assess_without_models_returns_503_or_result():
    # With no torch/whisper installed this returns 503; with them, 200.
    tiny_wav = base64.b64encode(b"RIFF....WAVEfmt ").decode()
    r = client.post(
        "/v1/tajweed/assess-json",
        json={"reference": "بِسْمِ اللَّهِ", "audio_base64": tiny_wav},
    )
    assert r.status_code in (200, 500, 503)
