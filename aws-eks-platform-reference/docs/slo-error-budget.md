# SLO and Error-Budget Model

This portfolio project includes an example service-level objective (SLO) model built from the application's real Prometheus request metrics. It demonstrates how SRE-style objectives and burn-rate alerts can be encoded without claiming that this reference workload has operated in production or achieved a historical SLO.

## Signals

The Flask service exports:

- `http_requests_total{method,route,status}` for request volume and HTTP outcomes.
- `http_request_duration_seconds` as a histogram for request latency.

The `/metrics` endpoint is excluded from application request metrics so Prometheus scraping does not inflate the service's own request volume.

## Example objectives

The default chart values use these illustrative objectives:

| Objective | Default | Interpretation |
| --- | ---: | --- |
| Availability / successful-request target | 99.9% | No more than 0.1% of measured requests should return HTTP 5xx over the SLO period. |
| Latency target | 95% | At least 95% of measured requests should complete within 500 ms. |

The availability objective is request-based, not a claim of host or cluster uptime. Client errors (4xx) are not counted as service failures in this example because they do not necessarily indicate server-side unavailability.

For a 30-day window, a 99.9% successful-request target permits an error budget of 0.1% of requests. If the same percentage were interpreted as pure time-based availability, it would correspond to roughly 43.2 minutes in 30 days, but this project uses request outcomes rather than downtime minutes.

## Recording rules

When `observability.prometheusRule.enabled=true`, the chart creates recording rules for:

- five-minute request rate;
- five-minute HTTP 5xx ratio;
- five-minute ratio of requests completing within the configured latency threshold.

Recording rules make dashboards and follow-up alerts easier to read while keeping the underlying PromQL visible in the chart.

## Burn-rate alerts

The availability error budget is `1 - 0.999 = 0.001` (0.1%). The default thresholds model two operating conditions:

- **Fast burn:** 5xx ratio above `0.0144` for five minutes. This is 14.4 times the nominal error-budget consumption rate and is marked critical.
- **Slow burn:** 5xx ratio above `0.006` for 30 minutes. This is six times the nominal error-budget consumption rate and is marked warning.

These are intentionally simple single-window examples. A production implementation would normally evaluate multiple windows together, tune thresholds to traffic volume and paging policy, and validate alert behavior with historical data.

## Latency alert

`PlatformDemoLatencyObjectiveAtRisk` warns when fewer than 95% of observed requests complete within 500 ms for ten minutes. The histogram bucket boundary is configurable through Helm values.

This is an objective-risk signal, not proof that a monthly latency SLO has been violated. Longer-window reporting should be handled by dashboards or dedicated SLO tooling.

## Low-traffic behavior

The PromQL uses `clamp_min` on request-rate denominators to avoid division-by-zero errors. That keeps rules numerically stable, but low traffic still needs operational judgment: a single failure can produce a high short-window error ratio. Production teams should add minimum-request-volume conditions or use SLO tooling designed for sparse traffic when appropriate.

## Scope and label isolation

The example rules assume the Prometheus deployment scrapes the intended application release. In a shared Prometheus environment, recording and alert expressions should additionally scope by stable target labels such as namespace, service, cluster, or environment to avoid combining unrelated releases.

## What this demonstrates

The project intentionally shows the engineering mechanics rather than fabricated results:

- selecting SLIs from actual application telemetry;
- translating an objective into an error budget;
- distinguishing fast and sustained budget burn;
- separating availability and latency objectives;
- documenting low-volume and shared-monitoring caveats;
- keeping thresholds configurable rather than hiding them in alert expressions.

No production SLO attainment, paging history, traffic volume, or error-budget consumption is claimed.
