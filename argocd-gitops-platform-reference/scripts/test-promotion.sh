#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-argocd-gitops-platform-reference}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

cp -R "${ROOT}" "${TMP_DIR}/reference"
TEST_ROOT="${TMP_DIR}/reference"

# Make staging newer than prod so CI can prove promotion changes only the target tag.
sed -i 's/newTag: 6.15.0/newTag: 6.16.0/' \
  "${TEST_ROOT}/workloads/podinfo/overlays/staging/kustomization.yaml"

python3 "${TEST_ROOT}/scripts/promote-image.py" staging prod --root "${TEST_ROOT}"

grep -q 'newTag: 6.16.0' \
  "${TEST_ROOT}/workloads/podinfo/overlays/prod/kustomization.yaml"
grep -q 'newTag: 6.16.0' \
  "${TEST_ROOT}/workloads/podinfo/overlays/staging/kustomization.yaml"
grep -q 'newTag: 6.15.0' \
  "${TEST_ROOT}/workloads/podinfo/overlays/dev/kustomization.yaml"

if python3 "${TEST_ROOT}/scripts/promote-image.py" dev prod --root "${TEST_ROOT}" >/dev/null 2>&1; then
  echo "ERROR: non-adjacent promotion unexpectedly succeeded" >&2
  exit 1
fi

echo "Promotion helper tests passed."
