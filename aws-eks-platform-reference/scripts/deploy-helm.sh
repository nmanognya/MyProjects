#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
IMAGE_TAG="${2:-}"
RELEASE_NAME="${RELEASE_NAME:-platform-demo}"
NAMESPACE="${NAMESPACE:-platform-demo}"
TIMEOUT="${TIMEOUT:-5m}"

case "${ENVIRONMENT}" in
  dev|staging|prod) ;;
  *)
    echo "Usage: $0 <dev|staging|prod> <immutable-image-tag>" >&2
    exit 64
    ;;
esac

if [[ -z "${IMAGE_TAG}" ]]; then
  echo "An immutable image tag is required; do not promote 'latest'." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_DIR="${PROJECT_DIR}/helm/platform-demo"
VALUES_FILE="${CHART_DIR}/values-${ENVIRONMENT}.yaml"

command -v helm >/dev/null 2>&1 || {
  echo "helm is required" >&2
  exit 69
}

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "Missing values file: ${VALUES_FILE}" >&2
  exit 66
fi

helm lint "${CHART_DIR}" --strict --values "${VALUES_FILE}"

helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}" \
  --set-string "image.tag=${IMAGE_TAG}" \
  --atomic \
  --wait \
  --timeout "${TIMEOUT}"

helm status "${RELEASE_NAME}" --namespace "${NAMESPACE}"
