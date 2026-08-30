# Release and Rollback Strategy

This project models a simple promotion path for one Helm chart across `dev`, `staging`, and `prod`. It is a portfolio reference implementation; it does not claim that these environments are currently deployed to a live AWS account.

## Environment overlays

The base chart contains shared workload behavior. Environment files change only the settings that should vary by release stage:

- `values-dev.yaml` keeps capacity and cost low for rapid feedback.
- `values-staging.yaml` preserves production-like availability behavior at smaller scale.
- `values-prod.yaml` raises minimum capacity, disruption protection, and alerting defaults.

CI lints, renders, and security-scans all three overlays on every Helm-related pull request. It also runs `bash -n` against the deploy, rollback, and smoke-test scripts so shell syntax failures are caught before merge.

## Artifact promotion

A release should promote the same immutable application artifact between environments. The application image should be built and scanned once, then referenced by the same immutable tag or digest in dev, staging, and production. Production should not rebuild source code that already passed staging validation.

The helper script requires an explicit image tag:

```bash
./scripts/deploy-helm.sh dev <immutable-image-tag>
./scripts/deploy-helm.sh staging <same-immutable-image-tag>
./scripts/deploy-helm.sh prod <same-immutable-image-tag>
```

The script deliberately refuses an omitted image tag. In a real delivery system, the tag or digest would normally come from trusted build or release metadata rather than a developer typing it manually.

## Deployment safety

`deploy-helm.sh` runs strict Helm linting before deployment and uses:

- `helm upgrade --install` for idempotent release management;
- `--atomic` so a failed upgrade is rolled back automatically;
- `--wait` so Helm waits for Kubernetes resources to become ready;
- a bounded timeout so failed readiness cannot block indefinitely.

After a successful Helm rollout, the script runs `smoke-test.sh` by default. This checks application behavior instead of treating Kubernetes readiness alone as proof that the release works.

Set `RUN_SMOKE_TESTS=false` only when another release system owns post-deployment verification.

## Post-deployment smoke tests

The smoke test validates:

- `/healthz` returns the expected healthy state;
- `/readyz` returns the expected ready state;
- `/` identifies `platform-demo` and reports `status=ok`;
- `/metrics` exposes the request counter and latency histogram used by the SLO rules.

For the default ClusterIP service, the script opens a temporary `kubectl port-forward` to the release Service and cleans it up on exit. This allows the checks to work without adding a public load balancer solely for validation.

An environment with ingress or an internal/external load balancer can bypass port-forwarding:

```bash
BASE_URL=https://platform-demo.example.internal ./scripts/smoke-test.sh
```

The test uses bounded curl timeouts and fails non-zero on unexpected HTTP responses or content. A failed smoke check therefore prevents a deployment wrapper from reporting success, but it does not automatically execute a second rollback after Helm has already completed. In a real production pipeline, that policy should be explicit: either invoke the existing rollback helper after smoke-test failure or let a deployment controller perform the rollback.

## Promotion gates

A production-style promotion flow would be:

1. Pull request passes Terraform, Helm, and application CI.
2. Build and scan one immutable application image.
3. Deploy that artifact to dev and run post-deployment smoke checks.
4. Promote the same artifact to staging and repeat smoke/integration validation.
5. Require an explicit approval before production promotion.
6. Deploy the same artifact to production using the production values overlay.
7. Run smoke checks, then watch rollout health, availability alerts, restart behavior, SLO burn signals, and application telemetry before declaring the release complete.

This repository does not add a workflow that deploys to AWS because no live cluster credentials or production environment are part of the portfolio. That boundary is intentional: CI validates code, manifests, and release-script syntax without pretending a live deployment occurred.

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

Automatic rollback through `--atomic` is appropriate for failures visible during the Helm rollout. A later regression detected by smoke tests or monitoring may require an operator-triggered rollback after the release has already reached Kubernetes readiness.

## Tradeoffs and limitations

- Environment overlays can drift if CI does not render every one; the matrix workflow is intended to catch this.
- Helm rollback restores Kubernetes release state but cannot automatically undo external database migrations or other irreversible side effects.
- CPU HPA and Kubernetes readiness are infrastructure signals, not proof that business functionality is healthy.
- Smoke tests are intentionally narrow and deterministic; they do not replace integration, load, or business-transaction testing.
- The default port-forward path validates the in-cluster Service path, not an ingress, WAF, DNS, or external load-balancer path. Use `BASE_URL` when those layers need validation.
- Manual production approval is described but not fabricated as an active GitHub Environment because this portfolio does not have a real production target.
- A mature delivery system should additionally use image digests, signed artifacts, deployment provenance, environment protection rules, and explicit rollback policy for post-deployment test failures.
