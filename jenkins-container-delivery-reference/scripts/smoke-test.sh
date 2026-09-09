#!/usr/bin/env bash
set -euo pipefail

url="${1:-http://127.0.0.1:8080/healthz}"
attempts="${SMOKE_ATTEMPTS:-10}"
sleep_seconds="${SMOKE_SLEEP_SECONDS:-2}"

for ((i=1; i<=attempts; i++)); do
  if response="$(curl --fail --silent --show-error --max-time 3 "$url")"; then
    if [[ "$response" == *'"status": "ok"'* ]]; then
      echo "Smoke test passed on attempt $i"
      exit 0
    fi
  fi

  if (( i < attempts )); then
    sleep "$sleep_seconds"
  fi
done

echo "Smoke test failed after $attempts attempts: $url" >&2
exit 1
