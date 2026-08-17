# Workload reliability and scaling

The `platform-demo` Helm chart is intentionally small, but it exposes the workload controls that matter when operating Kubernetes services.

## Availability model

The default deployment starts with two replicas and uses a rolling update strategy with `maxUnavailable: 0` and `maxSurge: 1`. This favors availability during planned rollouts at the cost of temporarily requiring capacity for one extra pod.

A PodDisruptionBudget keeps at least one replica available during voluntary disruptions such as node maintenance. It does not protect against application crashes, node failures, or an Availability Zone outage, so readiness probes and replica placement still matter.

## Health checks

Readiness and liveness checks use separate timings. Readiness controls whether a pod receives Service traffic. Liveness is deliberately slower so a temporarily busy container is not restarted too aggressively.

The demo uses a simple HTTP root endpoint because the container is intentionally generic. A real application should expose explicit readiness and liveness endpoints that test only the dependencies appropriate to each signal.

## Resource governance

CPU and memory requests are set so the scheduler has a concrete placement signal. Limits bound resource consumption for the demo. These values are examples and should be adjusted from observed workload behavior rather than copied into a production service unchanged.

## Autoscaling

The HPA uses CPU utilization with a minimum of two and maximum of six replicas. Scale-down is stabilized for five minutes to reduce oscillation, while scale-up can react more quickly.

HPA requires a metrics provider such as Metrics Server. CPU-based scaling is only a starting point; queue depth, request concurrency, latency, or other application-specific signals can be better scaling inputs for real services.

## Security defaults

The pod runs as a non-root user with the RuntimeDefault seccomp profile. Privilege escalation is disabled, all Linux capabilities are dropped, and the root filesystem is read-only. The dedicated ServiceAccount does not automatically mount its Kubernetes API token because the demo has no API access requirement.

Future workload identity work should attach cloud permissions only when the application needs them and keep those permissions separate from the node IAM role.

## Validation

The Helm CI workflow performs strict chart linting, renders the manifests, and scans the rendered Kubernetes configuration for HIGH and CRITICAL findings. Rendering before the security scan ensures the scanner evaluates concrete Kubernetes resources rather than unresolved Go templates.
