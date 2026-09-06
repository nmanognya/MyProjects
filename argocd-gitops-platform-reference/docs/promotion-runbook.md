# Promotion and rollback runbook

## Promotion principle

Promotion changes Git desired state; it does not run `kubectl set image`, patch live Deployments, or rebuild the artifact for each environment. A releasable image version is selected once, then the environment overlay is changed through review.

For a real service, prefer an immutable registry digest when the release pipeline exposes one. This demo workload uses a versioned public image tag because the repository does not own or publish the podinfo artifact.

## Dev to staging

1. Confirm the candidate has reconciled successfully in dev.
2. Change only the staging overlay's image reference or release-specific configuration.
3. Open a PR and review the rendered diff and CI checks.
4. Merge the PR.
5. Argo CD detects the new `main` revision and automatically reconciles staging.
6. Check Application health and workload behavior before proposing production promotion.

## Staging to production

1. Promote the exact candidate already validated in staging; do not rebuild it for production.
2. Change only the production overlay.
3. Review the Git diff, CI output, operational risk, and rollback compatibility.
4. Merge the PR. Production becomes `OutOfSync` because automatic sync is disabled.
5. An operator reviews the Argo CD diff and triggers production sync.
6. Verify Argo CD reports `Synced` and `Healthy`, then perform service-specific smoke checks.

The manual sync boundary is intentional. Approval happens before the production reconciliation action, while Git remains the source of desired state.

## Rollback

Normal rollback is a Git revert of the promotion commit followed by reconciliation. This makes the rollback visible in both Git history and Argo CD.

Do not assume a Kubernetes rollback reverses database migrations, messages already published, object-storage writes, or calls to external systems. Releases with irreversible side effects need backward-compatible schema and data-migration strategies.

## Drift response

- **Dev/staging:** Argo CD self-heals Git-managed drift automatically. Investigate repeated drift rather than continuously fighting the reconciler.
- **Production:** inspect the diff first. If the live change was an emergency fix worth retaining, encode it in Git before synchronizing. If it was unauthorized or accidental, sync the reviewed Git state.
- **Persistent controller-owned differences:** use narrowly scoped Argo CD ignore rules only when ownership is understood. Do not suppress broad fields merely to make an Application appear green.

## Recovery boundaries

If Argo CD is unavailable, existing application pods continue to run but desired-state changes and drift correction pause. Recover the GitOps control plane before forcing ad-hoc application mutations unless an incident requires a documented break-glass action.

This runbook is a portfolio operating model. It does not claim that these steps were exercised against a live production cluster.
