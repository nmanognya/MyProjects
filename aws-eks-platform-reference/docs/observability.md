# Observability and Alerting

This portfolio project separates infrastructure observability from application telemetry so it does not imply metrics that the demo workload does not actually emit.

## Current scope

The Helm chart can optionally create a `PrometheusRule` for platform-level signals exposed by `kube-state-metrics`:

- Deployment available replicas falling below desired replicas for a sustained period.
- Repeated container restarts within a configurable time window.

The rules are disabled by default because `PrometheusRule` is a Custom Resource Definition normally supplied by the Prometheus Operator / kube-prometheus-stack. Enabling the rules without that CRD installed would make the release fail.

Example values override:

```yaml
observability:
  prometheusRule:
    enabled: true
    labels:
      release: kube-prometheus-stack
    availabilityFor: 10m
    restartWindow: 15m
    restartThreshold: 3
```

The `labels` map exists because many Prometheus Operator installations select rules by label. The exact selector is environment-specific and should match the monitoring stack configuration rather than being hard-coded into this reusable chart.

## Why these alerts

### Sustained replica unavailability

The deployment alert compares desired replicas with available replicas. A `for` duration avoids paging on short rolling-update or scheduling transitions. The signal is useful for capacity shortages, failed readiness checks, image failures, and other conditions that leave the deployment below desired availability.

### Restart bursts

The restart alert uses the increase in container restart counters over a window instead of alerting on a historical lifetime total. This focuses the alert on active instability such as crash loops or repeated liveness-probe failures.

## Dependencies and limitations

These rules assume:

- Prometheus Operator CRDs are installed when `prometheusRule.enabled=true`.
- Prometheus discovers the generated rule.
- `kube-state-metrics` is scraped and exposes the referenced metrics.

The current nginx demo does not expose application-specific Prometheus metrics. There is therefore no `ServiceMonitor` in the chart today. Adding one would create a misleading configuration unless the workload first exposes a real `/metrics` endpoint.

The workload IAM permission for `cloudwatch:PutMetricData` is also intentionally separate from these Prometheus rules. It demonstrates narrow AWS workload identity plumbing; the demo application does not currently publish custom CloudWatch metrics.

## Production follow-ups

A production implementation would normally add application telemetry around request rate, error rate, and latency, then connect those signals to service-level objectives. Alert routing should distinguish symptom-based alerts that need action from informational dashboards and capacity trends.

For this reference implementation, the next useful evolution is to add a small instrumented application or exporter and then demonstrate a real `ServiceMonitor`, recording rules, SLO/error-budget calculations, and runbook links.
