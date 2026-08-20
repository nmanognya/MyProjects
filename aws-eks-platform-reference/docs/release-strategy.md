# Release and Rollback Strategy

This project models a simple promotion path for one Helm chart across `dev`, `staging`, and `prod`. It is a portfolio reference implementation; it does not claim that these environments are currently deployed to a live AWS account.

## Environment overlays

The base chart contains shared workload behavior. Environment files change only the settings that should vary by release stage:

- `values-dev.yaml` keeps capacity and cost low for rapid feedback.
- `values-staging.yaml` preserves production-like availability behavior at smaller scale.
- `values-prod.yaml` raises minimum capacity, disruption protection, and alerting defaults.

CI lints, renders, and security-scans all three overlays on every Helm-related pull request. This prevents an override that works in one environment from silently breaking another.

## Artifact promotion

A release should promote the same immutable application artifact between environments. The application image should be built and scanned once, then referenced by the same immutable tag or digest in dev, staging, and production. Production should not rebuild source code that already passed staging validation.

The helper script requires an explicit image tag:

```bash
./scripts/deploy-helm.sh dev <immutable-image-tag>
./scripts/deploy-helm.sh staging <same-immutable-image-tag>
./scripts/deploy-helm.sh prod <same-immutable-image-tag>
```

The script deliberately refuses an omitted image tag. In a real delivery system, the tag or digest would normally come from a trusted build artifact or release metadata rather than a developer typing it manually.

## Deployment safety

`deploy-helm.sh` runs strict Helm linting before deployment and uses:

- `helm upgrade --install` for idempotent release management;
- `--atomic` so a failed upgrade is rolled back automatically;
- `--wait` so Helm waits for Kubernetes resources to become ready;
- a bounded timeout so failed readiness cannot block indefinitely.

The current chart also uses readiness/liveness probes, rolling-update controls, a PDB where enabled, and HPA configuration. These controls reduce deployment risk but do not replace application-level smoke tests or business validation.

## Promotion gates

A production-style promotion flow would be:

1. Pull request passes Terraform and Helm CI.
2. Build and scan one immutable application image.
3. Deploy that artifact to dev and run smoke/integration checks.
4. Promote the same artifact to staging and validate production-like behavior.
5. Require an explicit approval before production promotion.
6. Deploy the same artifact to production using the production values overlay.
7. Watch rollout health, availability alerts, restart behavior, and application telemetry before declaring the release complete.

This repository does not add a workflow that deploys to AWS because no live cluster credentials or production environment are part of the portfolio. That boundary is intentional: CI validates code and rendered manifests without pretending a deployment occurred.

## Rollback

Helm keeps release history. Before a manual rollback, inspect revisions:

```bash
helm history platform-demo --namespace platform-demo
```

Then roll back explicitly:

```bash
./scripts/rollback-helm.sh <revision>
```

The rollback script waits for the selected revision to become ready and prints final release status.

Automatic rollback through `--atomic` is appropriate for failures visible during the Helm rollout. A later application regression may require an operator-triggered rollback after monitoring or smoke tests detect the problem.

## Tradeoffs and limitations

- Environment overlays can drift if CI does not render every one; the matrix workflow is intended to catch this.
- Helm rollback restores Kubernetes release state but cannot automatically undo external database migrations or other irreversible side effects.
- CPU HPA and Kubernetes readiness are infrastructure signals, not proof that business functionality is healthy.
- Manual production approval is described but not fabricated as an active GitHub Environment because this portfolio does not have a real production target.
- A mature delivery system should use image digests, signed artifacts, deployment provenance, post-deploy smoke tests, and environment protection rules.
