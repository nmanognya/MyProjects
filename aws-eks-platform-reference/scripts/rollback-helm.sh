#!/usr/bin/env bash
set -euo pipefail

REVISION="${1:-}"
RELEASE_NAME="${RELEASE_NAME:-platform-demo}"
NAMESPACE="${NAMESPACE:-platform-demo}"
TIMEOUT="${TIMEOUT:-5m}"

if [[ -z "${REVISION}" || ! "${REVISION}" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <helm-revision>" >&2
  exit 64
fi

command -v helm >/dev/null 2>&1 || {
  echo "helm is required" >&2
  exit 69
}

helm history "${RELEASE_NAME}" --namespace "${NAMESPACE}"

helm rollback "${RELEASE_NAME}" "${REVISION}" \
  --namespace "${NAMESPACE}" \
  --wait \
  --timeout "${TIMEOUT}"

helm status "${RELEASE_NAME}" --namespace "${NAMESPACE}"
