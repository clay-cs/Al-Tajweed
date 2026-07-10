# Tajweed AI service. CPU image by default; for GPU build with
#   --build-arg BASE=nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04
# and install a CUDA torch wheel, then run with `--gpus all` + DEVICE=cuda.
ARG BASE=python:3.11-slim
FROM ${BASE}

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HF_HOME=/models \
    DEVICE=auto \
    PORT=8001

# ffmpeg + libsndfile: decode m4a/aac/ogg from mobile and read wav.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Pre-create the model cache so a mounted volume keeps weights warm.
RUN mkdir -p /models

EXPOSE 8001
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request,sys; \
        urllib.request.urlopen('http://localhost:8001/health'); sys.exit(0)" \
        || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
