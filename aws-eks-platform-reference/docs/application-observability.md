# Application observability

The `platform-demo` workload is a small Flask service used only for this portfolio reference architecture. It exposes real application telemetry so the monitoring examples do not invent signals that the workload cannot produce.

## Endpoints

- `/` returns a simple service response.
- `/healthz` is used by the Kubernetes liveness probe.
- `/readyz` is used by the Kubernetes readiness probe.
- `/metrics` exposes Prometheus metrics.
- `/simulate-error` returns HTTP 500 intentionally for local/demo observability testing.

## Metrics

The service exports:

- `http_requests_total{method,route,status}` for request volume and errors.
- `http_request_duration_seconds{method,route}` for request latency.

The metrics endpoint itself is excluded from request metrics to reduce scrape-induced noise.

## Prometheus discovery

The Helm chart can create a Prometheus Operator `ServiceMonitor` when `observability.serviceMonitor.enabled=true`. It is disabled by default because `ServiceMonitor` is a custom resource and the chart should remain renderable on clusters without Prometheus Operator installed.

The `ServiceMonitor` selects the workload Service by stable Kubernetes labels and scrapes the named `http` port at `/metrics`. Scrape interval and timeout are configurable.

## Container and CI controls

The application container runs as UID 10001 behind Gunicorn and is compatible with the chart's non-root, read-only-root-filesystem security context. CI installs pinned application dependencies, runs unit tests, builds the container, and blocks on HIGH/CRITICAL Trivy findings with fixes available.

The CI workflow builds and scans the image but does not publish it. Publishing to GHCR and signing/provenance should be added only when the repository has a deliberate release workflow and required registry permissions.

## Deliberate limitations

This repository does not claim live Prometheus data, production traffic, an SLO attainment percentage, or a deployed monitoring stack. Application-level alert thresholds and SLO/error-budget rules should be added after the metric names and label cardinality are stable.
