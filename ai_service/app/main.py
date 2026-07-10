"""FastAPI entrypoint for the Tajweed AI service.

Endpoints:
  GET  /health                 — liveness + which models are available
  POST /v1/tajweed/assess      — multipart (audio file + reference verse)
  POST /v1/tajweed/assess-json — JSON (base64 audio + reference)

The heavy pipeline is imported lazily inside the handlers so the process
starts instantly and `/health` works even while models are still cold.
"""

from __future__ import annotations

import base64

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .config import settings
from .schemas import AssessmentResult, HealthResponse

app = FastAPI(
    title="Quran AI — Tajweed Assessment",
    version="1.0.0",
    description="Letter-level Quran recitation & Tajweed analysis.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    from . import asr

    return HealthResponse(
        status="ok",
        device=settings.device,
        models_loaded=asr.models_ready(),
        whisper_model=settings.whisper_model,
        w2v_model=settings.w2v_model,
    )


def _run(audio: bytes, reference: str) -> AssessmentResult:
    if not reference or not reference.strip():
        raise HTTPException(400, "reference verse is required")
    if not audio:
        raise HTTPException(400, "empty audio")
    from . import asr
    from .assessor import assess

    try:
        return assess(audio, reference)
    except asr.ModelsUnavailable as e:
        raise HTTPException(
            503, f"AI models unavailable: {e}. Install requirements and "
                 "ensure model weights are reachable."
        )
    except Exception as e:  # pragma: no cover - defensive
        raise HTTPException(500, f"assessment failed: {e}")


@app.post("/v1/tajweed/assess", response_model=AssessmentResult)
async def assess_multipart(
    reference: str = Form(...),
    audio: UploadFile = File(...),
) -> AssessmentResult:
    data = await audio.read()
    return _run(data, reference)


class AssessJson(BaseModel):
    reference: str
    audio_base64: str


@app.post("/v1/tajweed/assess-json", response_model=AssessmentResult)
def assess_json(body: AssessJson) -> AssessmentResult:
    try:
        data = base64.b64decode(body.audio_base64)
    except Exception:
        raise HTTPException(400, "audio_base64 is not valid base64")
    return _run(data, body.reference)


if __name__ == "__main__":  # pragma: no cover
    import uvicorn

    uvicorn.run(
        "app.main:app", host=settings.host, port=settings.port, reload=False
    )
