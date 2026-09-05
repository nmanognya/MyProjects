#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: smoke-test.sh <url> [expected_text]

Validates an HTTP endpoint with bounded retries before a slot promotion.
- Requires an HTTP 2xx response.
- Optionally requires a literal response-body string.
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

url="${1%/}"
expected_text="${2:-}"
max_attempts="${SMOKE_MAX_ATTEMPTS:-6}"
retry_seconds="${SMOKE_RETRY_SECONDS:-10}"
connect_timeout="${SMOKE_CONNECT_TIMEOUT_SECONDS:-5}"
max_time="${SMOKE_MAX_TIME_SECONDS:-20}"

if ! [[ "$max_attempts" =~ ^[1-9][0-9]*$ ]]; then
  echo "SMOKE_MAX_ATTEMPTS must be a positive integer" >&2
  exit 2
fi

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  http_code="$(curl \
    --silent \
    --show-error \
    --location \
    --output "$response_file" \
    --write-out '%{http_code}' \
    --connect-timeout "$connect_timeout" \
    --max-time "$max_time" \
    "$url" || true)"

  if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    if [[ -z "$expected_text" ]] || grep --fixed-strings --quiet -- "$expected_text" "$response_file"; then
      echo "Smoke test passed for ${url} on attempt ${attempt}/${max_attempts} (HTTP ${http_code})."
      exit 0
    fi

    echo "Attempt ${attempt}/${max_attempts}: HTTP ${http_code}, but expected response text was not found." >&2
  else
    echo "Attempt ${attempt}/${max_attempts}: endpoint returned HTTP ${http_code:-000}." >&2
  fi

  if (( attempt < max_attempts )); then
    sleep "$retry_seconds"
  fi
done

echo "Smoke test failed for ${url} after ${max_attempts} attempts." >&2
exit 1
