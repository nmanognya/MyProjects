#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-argocd-gitops-platform-reference}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

for env in dev staging prod; do
  overlay="${ROOT}/workloads/podinfo/overlays/${env}"
  kustomization="${overlay}/kustomization.yaml"
  rendered="$(kubectl kustomize "${overlay}")"

  grep -q 'kind: Deployment' <<<"${rendered}" || fail "${env}: Deployment missing"
  grep -q 'kind: Service' <<<"${rendered}" || fail "${env}: Service missing"
  grep -q 'kind: PodDisruptionBudget' <<<"${rendered}" || fail "${env}: PDB missing"
  grep -q "namespace: podinfo-${env}" <<<"${rendered}" || fail "${env}: namespace transform missing"
  grep -q 'name: ghcr.io/stefanprodan/podinfo' "${kustomization}" || fail "${env}: image override missing"
  [[ "$(grep -c 'newTag:' "${kustomization}")" -eq 1 ]] || fail "${env}: expected exactly one newTag"

  if grep -Eq 'image: .*:(latest|main|master)([[:space:]]|$)' <<<"${rendered}"; then
    fail "${env}: mutable branch/latest-style image reference is forbidden"
  fi
done

for env in dev staging; do
  app="${ROOT}/argocd/applications/${env}.yaml"
  grep -q 'automated:' "${app}" || fail "${env}: automated sync must be enabled"
  grep -q 'prune: true' "${app}" || fail "${env}: prune must be enabled"
  grep -q 'selfHeal: true' "${app}" || fail "${env}: self-heal must be enabled"
done

prod_app="${ROOT}/argocd/applications/prod.yaml"
if grep -q 'automated:' "${prod_app}"; then
  fail "prod: automated sync must remain disabled"
fi

grep -q 'targetRevision: main' "${prod_app}" || fail "prod: expected tracked revision is main"
grep -q 'namespace: podinfo-prod' "${prod_app}" || fail "prod: destination namespace mismatch"

echo "GitOps validation passed."
