#!/usr/bin/env bash
set -euo pipefail

RELEASE_NAME="${RELEASE_NAME:-platform-demo}"
NAMESPACE="${NAMESPACE:-platform-demo}"
BASE_URL="${BASE_URL:-}"
LOCAL_PORT="${LOCAL_PORT:-18080}"
CURL_MAX_TIME="${CURL_MAX_TIME:-5}"
PORT_FORWARD_PID=""

cleanup() {
  if [[ -n "${PORT_FORWARD_PID}" ]]; then
    kill "${PORT_FORWARD_PID}" >/dev/null 2>&1 || true
    wait "${PORT_FORWARD_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

command -v curl >/dev/null 2>&1 || {
  echo "curl is required" >&2
  exit 69
}

if [[ -z "${BASE_URL}" ]]; then
  command -v kubectl >/dev/null 2>&1 || {
    echo "kubectl is required when BASE_URL is not provided" >&2
    exit 69
  }

  kubectl --namespace "${NAMESPACE}" port-forward "service/${RELEASE_NAME}" "${LOCAL_PORT}:80" >/tmp/platform-demo-port-forward.log 2>&1 &
  PORT_FORWARD_PID=$!
  BASE_URL="http://127.0.0.1:${LOCAL_PORT}"

  for _ in {1..20}; do
    if curl --silent --fail --max-time "${CURL_MAX_TIME}" "${BASE_URL}/healthz" >/dev/null; then
      break
    fi
    if ! kill -0 "${PORT_FORWARD_PID}" >/dev/null 2>&1; then
      cat /tmp/platform-demo-port-forward.log >&2 || true
      echo "kubectl port-forward exited before the service became reachable" >&2
      exit 1
    fi
    sleep 1
  done
fi

request() {
  local path="$1"
  curl --silent --show-error --fail --max-time "${CURL_MAX_TIME}" "${BASE_URL}${path}"
}

HEALTH_BODY="$(request /healthz)"
READY_BODY="$(request /readyz)"
ROOT_BODY="$(request /)"
METRICS_BODY="$(request /metrics)"

[[ "${HEALTH_BODY}" == *'"status":"healthy"'* ]] || {
  echo "health check returned unexpected content" >&2
  exit 1
}

[[ "${READY_BODY}" == *'"status":"ready"'* ]] || {
  echo "readiness check returned unexpected content" >&2
  exit 1
}

[[ "${ROOT_BODY}" == *'"service":"platform-demo"'* ]] || {
  echo "root endpoint did not identify the expected service" >&2
  exit 1
}

[[ "${ROOT_BODY}" == *'"status":"ok"'* ]] || {
  echo "root endpoint returned an unexpected service status" >&2
  exit 1
}

[[ "${METRICS_BODY}" == *"http_requests_total"* ]] || {
  echo "Prometheus request counter is missing" >&2
  exit 1
}

[[ "${METRICS_BODY}" == *"http_request_duration_seconds"* ]] || {
  echo "Prometheus latency histogram is missing" >&2
  exit 1
}

echo "Smoke tests passed for ${BASE_URL}"
