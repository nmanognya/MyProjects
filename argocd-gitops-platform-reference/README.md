# Argo CD GitOps Platform Reference

Production-style GitOps reference showing how a platform team can manage the same Kubernetes workload across dev, staging, and production with Git as the desired-state source.

## What this demonstrates

- Argo CD `AppProject` tenancy and destination restrictions
- separate `Application` resources for dev, staging, and production
- Kustomize base/overlay composition without copied manifests
- automated reconciliation and drift correction for lower environments
- intentionally manual production synchronization
- namespace isolation and environment-specific capacity settings
- hardened Kubernetes workload settings, probes, resource controls, and PDB
- CI rendering/schema checks plus explicit GitOps contract tests
- reviewed promotion, rollback, and drift-response runbooks

The workload uses `ghcr.io/stefanprodan/podinfo:6.15.0` as a public demo image. The project does not claim ownership of that image or a live cluster deployment.

## Repository layout

```text
argocd-gitops-platform-reference/
├── argocd/
│   ├── project.yaml
│   └── applications/{dev,staging,prod}.yaml
├── docs/
│   ├── promotion-runbook.md
│   └── reconciliation-model.md
├── scripts/validate-gitops.sh
└── workloads/podinfo/
    ├── base/
    └── overlays/{dev,staging,prod}/
```

## Operating model

1. Application code is built elsewhere and produces a versioned, preferably immutable artifact.
2. A promotion PR changes only the intended environment overlay.
3. CI renders every overlay, validates standard Kubernetes schemas, rejects mutable `latest`/branch-style image references, and enforces environment sync contracts.
4. Argo CD reconciles dev/staging automatically after merge.
5. Production remains manual-sync so an operator can review health and change context before reconciliation.
6. Normal rollback is a Git revert to a known-good desired state, followed by Argo CD reconciliation.

## Validation

Run locally with a compatible `kubectl` client:

```bash
bash argocd-gitops-platform-reference/scripts/validate-gitops.sh
```

GitHub Actions additionally pipes all rendered workload overlays through Kubeconform in strict mode. Argo CD CRDs are treated separately from standard workload schema validation because their schemas depend on the installed Argo CD version.

## Deliberate boundaries

This project focuses on GitOps control-plane behavior, not cluster provisioning. It assumes Argo CD and target Kubernetes clusters/namespaces already exist. Secrets are not committed; a production implementation should integrate an external secret-management mechanism such as External Secrets Operator, CSI Secrets Store, or an organizational sealed-secret workflow.

Three explicit Applications are used instead of an ApplicationSet so the different environment reconciliation policies remain obvious in a small portfolio example. An ApplicationSet is more useful when the fleet grows enough that generator-driven composition reduces meaningful operational duplication.

See `docs/reconciliation-model.md` for drift and failure behavior and `docs/promotion-runbook.md` for the release operating model.

## Limitations

- no live Argo CD or Kubernetes cluster is provisioned or claimed
- production uses manual sync but this repository cannot enforce human approval configuration inside an external Argo CD installation
- the public demo image uses a version tag rather than a digest controlled by this repository
- secrets delivery, ingress, service mesh, and multi-cluster failover are intentionally outside this project's current scope
