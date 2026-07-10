# Quran AI — Tajweed Assessment Service

A production-grade, letter-level Quran recitation & Tajweed analysis
microservice. It does **not** rely on Whisper transcription alone — the
pronunciation judgement comes from a character-level Wav2Vec2 CTC acoustic
model with forced alignment and Goodness-of-Pronunciation (GOP) scoring.

```
audio bytes ──► preprocess ──► VAD ──► noise reduction
                                          │
        ┌─────────────────────────────────┴───────────────┐
        ▼                                                  ▼
  faster-whisper                                   Wav2Vec2 CTC
  (word transcript + timings)                (char posteriors / phonemes)
        │                                                  │
        │                                     forced alignment (CTC Viterbi)
        │                                                  │
        │                              per-letter GOP · duration · heaviness
        │                                                  │
        └──────────────► letter alignment ◄───────────────┘
                          (confusable-aware)
                                  │
                          Tajweed rule engine  (23 rules, extensible)
                                  │
                              final scoring
                                  │
                          structured JSON result
```

## Why these models

| Stage | Model | Why |
|-------|-------|-----|
| Transcription | **faster-whisper** (CTranslate2) | 4× faster / lower memory than vanilla Whisper (int8 on CPU, fp16 on GPU), strong Arabic coverage. Gives *what* was recited + word timings. Point `WHISPER_MODEL` at a ct2-converted `tarteel-ai/whisper-*-ar-quran` for Quran-tuned accuracy. |
| Pronunciation | **Wav2Vec2-XLSR-53-Arabic** (CTC) | Emits **characters**, the exact unit Tajweed reasons about (Whisper emits BPE subwords). CTC posteriors give robust per-letter forced alignment, GOP, and confusable-substitution detection — pronunciation over transcription. |
| VAD | **Silero VAD** (energy fallback) | Trims silence/noise so the acoustic model only sees speech. |
| Denoise | **noisereduce** | Spectral-gating noise reduction for phone-quality audio. |

Swappable via env vars — the pipeline is model-agnostic. You can drop in
Meta **MMS**, **HuBERT**, or **WhisperX** by adapting `asr.py` (the rest of
the engine consumes generic per-letter acoustics).

## Endpoints

| Method | Path | Body |
|--------|------|------|
| GET | `/health` | — → device, models_loaded |
| POST | `/v1/tajweed/assess` | multipart: `reference` (str) + `audio` (file) |
| POST | `/v1/tajweed/assess-json` | JSON: `{ reference, audio_base64 }` |

### Example response

```json
{
  "score": 92,
  "correct": true,
  "transcript": "بسم الله الرحمن الرحيم",
  "reference": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
  "confidence": 0.91,
  "letters": [
    { "index": 3, "letter": "ن", "heard": "ن", "status": "correct",
      "rule": null, "confidence": 0.97, "start": 1.2, "end": 1.5 }
  ],
  "words": [
    { "index": 0, "expected": "بسم", "heard": "بسم",
      "status": "correct", "start": 0.0, "end": 0.7, "confidence": 0.98 }
  ],
  "tajweed_errors": [
    { "rule": "Ikhfa", "severity": "medium", "letter_index": 3,
      "start": 1.2, "end": 1.5, "expected": "≥2 harakah ghunnah",
      "observed": "0.7 harakah",
      "feedback": "Ixfo to‘g‘ri bajarilmadi — ..." }
  ],
  "timing": { "audio_seconds": 4.1, "speech_seconds": 3.6,
              "words_per_minute": 49.5 },
  "feedback": ["Umumiy ball: 92/100.", "..."],
  "engine": "faster-whisper + wav2vec2-ctc"
}
```

## Tajweed rules covered

Ghunnah · Ikhfa · Idgham · Idgham Bila Ghunnah · Idgham Ma'a Ghunnah ·
Iqlab · Izhar · Izhar Shafawi · Ikhfa Shafawi · Idgham Shafawi ·
Noon Sakinah · Meem Sakinah · Madd · Madd Munfasil · Madd Muttasil ·
Madd Lazim · Madd Arid · Qalqalah · Tafkhim · Tarqiq · Lam Shamsiyyah ·
Lam Qamariyyah · Waqf · Ibtida · Makharij · Sifaat.

**Add a rule** in three lines — subclass `Rule`, decorate with
`@register`, append nothing else:

```python
# app/tajweed/rules_myrule.py
from .engine import Rule, RuleFinding, register

@register
class MyRule(Rule):
    name = "MyRule"
    def check(self, tokens, acoustics):
        return [RuleFinding("MyRule", 0, True, "low", "detected")]
```

Then import it in `engine.py`'s bottom block. Done.

## Arabic error detection

Letter-level: **missing**, **extra**, **wrong**, **substituted**, plus
similar-sounding confusions handled by the aligner:
`ض↔ظ · ص↔س · ذ↔ز · ق↔ك · ط↔ت · ح↔ه · ع↔ا` (and more in `arabic.py`).

## Run

### Docker (recommended)

```bash
cd ai_service
docker compose up --build          # CPU
# GPU: set DEVICE=cuda, uncomment the deploy block, run with NVIDIA runtime
```

First call downloads model weights into the `tajweed-models` volume
(cached afterwards).

### Local (dev)

```bash
cd ai_service
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --port 8001
```

### GPU vs CPU

`DEVICE=auto` (default) uses CUDA when `torch.cuda.is_available()`, else
CPU. `WHISPER_COMPUTE` defaults to `float16` on GPU, `int8` on CPU. Force
with `DEVICE=cpu` / `DEVICE=cuda`.

## Tests

The linguistic core, aligner, rule engine and scoring are **pure Python**
and unit-tested without the multi-GB ML stack:

```bash
pip install -r requirements-core.txt
pytest                    # 33 tests, ~0.5s
```

`tests/test_api.py` exercises the FastAPI layer and asserts a graceful
`503` when models aren't installed (never a crash).

## Configuration (env)

| Var | Default | Meaning |
|-----|---------|---------|
| `DEVICE` | `auto` | `auto` / `cpu` / `cuda` |
| `WHISPER_MODEL` | `small` | ct2 model name or path |
| `WHISPER_COMPUTE` | `int8`/`float16` | compute type |
| `W2V_MODEL` | `jonatasgrosman/wav2vec2-large-xlsr-53-arabic` | CTC char model |
| `NOISE_REDUCTION` | `1` | enable spectral denoise |
| `SAMPLE_RATE` | `16000` | working sample rate |
| `MAX_AUDIO_SECONDS` | `120` | hard cap on clip length |
| `GOP_INCORRECT` / `GOP_UNCLEAR` | `0.20` / `0.45` | letter GOP thresholds |
| `PORT` | `8001` | HTTP port |

## Architecture notes

- **Modular**: `arabic` (linguistics) → `align` (sequence) → `tajweed`
  (rules) → `scoring` are all ML-free and independently testable;
  `audio` / `asr` / `acoustics` hold every heavy import behind lazy loads.
- **Graceful degradation**: missing optional deps never crash — VAD falls
  back to energy gating, denoise to passthrough, and the API returns a
  clear `503` when the ML stack is absent.
- **Extensible**: rules self-register; models are env-swappable.
