FROM python:3.13.15-alpine3.24

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apk upgrade --no-cache \
    && adduser -D -u 10001 -s /sbin/nologin appuser

COPY requirements.txt .
RUN pip install --no-cache-dir --requirement requirements.txt \
    && python -m pip uninstall --yes pip

COPY app.py .

USER 10001
EXPOSE 8080

CMD ["gunicorn", "--bind=0.0.0.0:8080", "--workers=1", "--threads=4", "--timeout=30", "app:app"]
