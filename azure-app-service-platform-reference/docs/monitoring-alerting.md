# Monitoring and alerting

This reference adds Azure Monitor metric alerts around two production-facing App Service signals: HTTP 5xx volume and average response time. The goal is to make service symptoms visible without pretending the portfolio has real traffic history or production-derived thresholds.

## Alert set

### HTTP 5xx

- Metric: `Microsoft.Web/sites` / `Http5xx`
- Aggregation: total
- Evaluation: every 5 minutes over a 5-minute window
- Default threshold: 5 responses
- Severity: 1

This is intentionally a simple symptom alert. A fixed count works for a small reference implementation but should be replaced or supplemented by a failure-rate signal when real request volume is available. Five failures out of ten requests and five failures out of one million requests have very different meanings.

### Response time

- Metric: `Microsoft.Web/sites` / `AverageResponseTime`
- Aggregation: average
- Evaluation: every 5 minutes over a 15-minute window
- Default threshold: 2 seconds
- Severity: 2

The longer window reduces sensitivity to short spikes. Average latency can still hide tail latency; a real service should prefer percentile-based application telemetry when its instrumentation supports it.

## Notification routing

The module accepts `alert_action_group_ids` rather than creating email, SMS, webhook, or incident-management destinations. This keeps notification ownership outside the reusable platform module and avoids committing personal contact information or inventing an enterprise paging integration.

An environment can pass one or more existing Azure Monitor Action Group resource IDs:

```hcl
module "platform" {
  # ...

  alert_action_group_ids = [
    azurerm_monitor_action_group.platform_oncall.id,
  ]
}
```

The default is an empty list. The alerts still exist and evaluate, but they do not notify anyone until routing is configured. A real production deployment should treat missing notification routing as a deployment-readiness failure rather than silently accepting it.

## Threshold ownership

Both thresholds are Terraform variables and must be tuned from observed traffic and latency before production use. The defaults are examples for demonstrating the control plane, not claimed SLOs or production baselines.

Useful production refinements include:

- separate warning and paging severities;
- request-rate-aware 5xx ratios rather than fixed error counts;
- percentile latency from Application Insights;
- synthetic availability tests from outside the App Service resource;
- deployment annotations and alert correlation;
- action-group routing to an incident-management platform with ownership and escalation policies.

## Staging versus production

These alerts scope the production Web App resource. Staging-slot validation should remain part of the release path before a slot swap. Alerting every non-production slot with production paging severity would add noise and weaken the signal.

## Failure and recovery behavior

Azure Monitor metric alerts auto-mitigate when the condition clears. Clearing an alert does not prove the underlying cause is fixed, and the Terraform configuration does not automate remediation or rollback. Operators should correlate alerts with App Service diagnostics, Application Insights traces, deployment history, dependency health, and recent configuration changes before choosing rollback or remediation.

## Scope boundaries

This repository does not claim that these alerts have fired against live production traffic, that the default thresholds are appropriate for a real workload, or that an Action Group/on-call system is configured. It demonstrates how those operational controls would be represented and parameterized in a production-style Azure platform reference.
