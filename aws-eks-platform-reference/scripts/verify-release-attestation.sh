#!/usr/bin/env bash
set -euo pipefail

DIGEST="${1:-}"
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-ghcr.io/nmanognya/platform-demo}"
SOURCE_REPOSITORY="${SOURCE_REPOSITORY:-nmanognya/MyProjects}"
SIGNER_WORKFLOW="${SIGNER_WORKFLOW:-nmanognya/MyProjects/.github/workflows/aws-eks-release.yml}"

if [[ ! "${DIGEST}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
  echo "Usage: $0 sha256:<digest>" >&2
  exit 64
fi

command -v gh >/dev/null 2>&1 || {
  echo "gh CLI is required to verify GitHub artifact attestations." >&2
  exit 69
}

IMAGE_URI="oci://${IMAGE_REPOSITORY}@${DIGEST}"

echo "Verifying build provenance for ${IMAGE_REPOSITORY}@${DIGEST}"

gh attestation verify "${IMAGE_URI}" \
  --repo "${SOURCE_REPOSITORY}" \
  --signer-workflow "${SIGNER_WORKFLOW}"

echo "Build provenance verification passed for ${DIGEST}."
