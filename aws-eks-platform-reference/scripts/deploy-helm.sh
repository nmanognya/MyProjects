#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
IMAGE_REFERENCE="${2:-}"
RELEASE_NAME="${RELEASE_NAME:-platform-demo}"
NAMESPACE="${NAMESPACE:-platform-demo}"
TIMEOUT="${TIMEOUT:-5m}"
RUN_SMOKE_TESTS="${RUN_SMOKE_TESTS:-true}"
VERIFY_PROVENANCE="${VERIFY_PROVENANCE:-true}"

case "${ENVIRONMENT}" in
  dev|staging|prod) ;;
  *)
    echo "Usage: $0 <dev|staging|prod> <image-tag|sha256:digest>" >&2
    exit 64
    ;;
esac

if [[ -z "${IMAGE_REFERENCE}" ]]; then
  echo "An explicit image tag or sha256 digest is required." >&2
  exit 64
fi

if [[ "${ENVIRONMENT}" == "prod" && ! "${IMAGE_REFERENCE}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
  echo "Production deployments require a sha256 image digest." >&2
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

if [[ "${ENVIRONMENT}" == "prod" && "${VERIFY_PROVENANCE}" == "true" ]]; then
  "${SCRIPT_DIR}/verify-release-attestation.sh" "${IMAGE_REFERENCE}"
elif [[ "${ENVIRONMENT}" == "prod" ]]; then
  echo "WARNING: production provenance verification explicitly disabled with VERIFY_PROVENANCE=${VERIFY_PROVENANCE}." >&2
fi

helm lint "${CHART_DIR}" --strict --values "${VALUES_FILE}"

IMAGE_SET_ARGS=(--set-string "image.tag=${IMAGE_REFERENCE}")
if [[ "${IMAGE_REFERENCE}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
  IMAGE_SET_ARGS=(--set-string "image.digest=${IMAGE_REFERENCE}" --set-string "image.tag=")
fi

helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}" \
  "${IMAGE_SET_ARGS[@]}" \
  --atomic \
  --wait \
  --timeout "${TIMEOUT}"

helm status "${RELEASE_NAME}" --namespace "${NAMESPACE}"

if [[ "${RUN_SMOKE_TESTS}" == "true" ]]; then
  RELEASE_NAME="${RELEASE_NAME}" NAMESPACE="${NAMESPACE}" "${SCRIPT_DIR}/smoke-test.sh"
else
  echo "Post-deployment smoke tests skipped because RUN_SMOKE_TESTS=${RUN_SMOKE_TESTS}."
fi
