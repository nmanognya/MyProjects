# Argo CD GitOps Platform Reference

Production-style GitOps reference showing how a platform team can manage the same Kubernetes workload across dev, staging, and production with Git as the desired-state source.

## What this demonstrates

- Argo CD `AppProject` tenancy and destination restrictions
- Separate `Application` resources for dev, staging, and production
- Kustomize base/overlay composition without copied manifests
- automated reconciliation for lower environments
- intentionally manual production synchronization
- namespace isolation and environment-specific replica/resource settings
- health probes, resource requests/limits, and PodDisruptionBudget
- explicit promotion through reviewed Git changes rather than mutable runtime edits

The workload uses `ghcr.io/stefanprodan/podinfo:6.15.0` as a public demo image. The project does not claim ownership of that image or a live cluster deployment.

## Repository layout

```text
argocd-gitops-platform-reference/
├── argocd/
│   ├── project.yaml
│   └── applications/
│       ├── dev.yaml
│       ├── staging.yaml
│       └── prod.yaml
└── workloads/podinfo/
    ├── base/
    └── overlays/{dev,staging,prod}/
```

## Operating model

1. Application code is built elsewhere and produces a versioned image.
2. A promotion PR changes only the intended environment overlay.
3. CI renders and validates the resulting manifests before review.
4. Argo CD reconciles dev/staging automatically after merge.
5. Production remains manual-sync so an operator can review health and change context before reconciliation.
6. Rollback is a Git revert to a known-good desired state, followed by Argo CD reconciliation.

## Deliberate boundaries

This project focuses on GitOps control-plane behavior, not cluster provisioning. It assumes Argo CD and target Kubernetes clusters/namespaces already exist. Secrets are not committed; a production implementation should integrate an external secret-management mechanism such as External Secrets Operator, CSI Secrets Store, or a sealed-secret workflow based on organizational requirements.

## Why separate Applications instead of one ApplicationSet initially?

Three explicit Applications keep environment policy differences obvious during review. Dev and staging can safely self-heal and prune, while production uses manual sync. An `ApplicationSet` becomes more valuable when the fleet grows enough that generator-driven composition reduces operational duplication without hiding important policy differences.

## Next steps

- add CI rendering/schema/policy validation
- document promotion, rollback, and drift-handling runbooks
- add an ApplicationSet example only if the environment fleet grows enough to justify it
