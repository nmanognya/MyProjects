# Kubernetes policy as code

The Helm CI pipeline evaluates rendered Kubernetes manifests with Conftest and Rego before the existing Trivy configuration scan. The goal is to make a small set of platform expectations explicit and reviewable instead of relying only on chart defaults or scanner heuristics.

## Enforced controls

The current policy applies to rendered `Deployment` and `Service` resources and requires:

- pod-level `runAsNonRoot: true`
- `RuntimeDefault` seccomp
- `allowPrivilegeEscalation: false`
- a read-only container root filesystem
- dropping all Linux capabilities
- CPU and memory requests and limits
- automatic ServiceAccount token mounting disabled
- no direct `LoadBalancer` Service exposure for this reference workload

These controls mirror decisions already made in the chart. Policy therefore acts as an independent CI guardrail: if a future Helm change weakens one of those settings, rendering can still succeed while Conftest blocks the change.

## Validation design

CI performs two policy checks:

1. An intentionally insecure fixture must fail policy evaluation. This proves the policy is capable of rejecting known-bad configuration rather than only demonstrating a passing example.
2. Each rendered dev, staging, and production manifest must pass the same policy set.

Conftest is executed from the Open Policy Agent project's `openpolicyagent/conftest:v0.69.0` container rather than an unmaintained third-party GitHub Action.

## Why this is separate from Trivy

Trivy remains useful for broad misconfiguration and vulnerability detection. The Rego policy layer serves a different purpose: it captures project-specific platform rules whose importance may not map cleanly to a generic scanner severity.

A policy failure should therefore be reviewed as a platform-contract change. It should not be silenced merely because Trivy passes.

## Scope and limitations

This is CI-time policy enforcement, not Kubernetes admission control. A manifest deployed through another path could bypass it. A production platform could reuse or translate these policies into an admission layer such as Gatekeeper or another policy controller, but this portfolio does not claim that such a controller is installed.

The policy is intentionally small. It does not try to encode every Kubernetes best practice, and it does not duplicate controls already better handled by IAM, image provenance verification, network policy, or cloud-level security services.

The `LoadBalancer` restriction is specific to this reference architecture. It preserves the current private-service assumption; a real ingress design would require a deliberate policy change and review.
