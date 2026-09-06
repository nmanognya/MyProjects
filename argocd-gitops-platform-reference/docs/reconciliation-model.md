# Reconciliation and environment policy

## Environment behavior

| Environment | Sync | Prune | Self-heal | Purpose |
| --- | --- | --- | --- | --- |
| dev | automatic | yes | yes | fast feedback and immediate drift correction |
| staging | automatic | yes | yes | production-like reconciliation before promotion |
| prod | manual | operator-triggered | no automatic self-heal | explicit production change-control boundary |

The difference is intentional. Git remains authoritative for every environment, but production reconciliation requires an operator action after the desired-state change has been reviewed and merged.

## AppProject boundary

`podinfo-platform` restricts source material to this repository and restricts destinations to three explicit namespaces on the in-cluster Kubernetes API. This prevents an Application in this project from silently targeting arbitrary clusters or namespaces.

Cluster-scoped resources are not granted by the project. The workload itself contains namespaced resources only. Namespace creation is requested through Argo CD's `CreateNamespace=true` sync option so the application controller can establish the configured destination namespace when permitted by the Argo CD installation.

## Drift behavior

For dev and staging, a manual `kubectl` change to a Git-managed field is expected to be corrected by Argo CD because `selfHeal` is enabled. Deleting a Git-managed object is also reconciled. Removing a resource from Git allows Argo CD to prune it after the change reaches the tracked revision.

Production deliberately does not self-heal automatically. Argo CD still reports drift (`OutOfSync`), but an operator reviews the difference and initiates synchronization. This avoids turning every unexpected production mutation into an immediate automated write while still making configuration drift visible.

## Rollback

The preferred rollback is a Git revert of the promotion commit. That keeps the audit trail aligned with the desired state. Argo CD revision history can help inspect prior states, but directly selecting an old Argo revision without reconciling Git creates a split source of truth and is therefore an emergency technique, not the normal workflow.

A Git rollback restores Kubernetes desired state only. It cannot reverse database migrations, external API side effects, or data changes. Those require application-specific compatibility and recovery design.

## Failure modes

- **Argo CD unavailable:** workloads keep running, but reconciliation and drift visibility stop until the control plane recovers.
- **Git unavailable:** Argo CD cannot fetch new desired state; existing workloads continue running.
- **invalid manifest:** CI should block the merge; if invalid state reaches Git, Argo CD reports sync failure rather than silently treating the deployment as healthy.
- **manual production drift:** surfaced as `OutOfSync`; it is not automatically overwritten in this reference.

This project does not claim a live Argo CD installation, cluster, deployment, or measured recovery time.
