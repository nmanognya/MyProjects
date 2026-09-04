# Azure App Service Platform Reference

A production-style Azure platform reference that demonstrates secure application hosting without Kubernetes. The project focuses on private networking, managed identity, Key Vault access, Azure Monitor, Terraform, deployment slots, and GitHub Actions using workload identity federation.

## Why this project exists

The AWS EKS reference demonstrates Kubernetes-heavy platform engineering. This project intentionally exercises a different operating model: a managed Azure PaaS platform with fewer cluster responsibilities and stronger emphasis on identity, network isolation, secretless application access, release controls, and platform observability.

## Target architecture

```text
GitHub Actions (OIDC)
        |
        v
Azure federated identity
        |
        v
Terraform
  |
  +-- Resource Group
  +-- VNet
  |    +-- App Service integration subnet
  |    +-- Private endpoint subnet
  +-- App Service Plan
  +-- Linux Web App + system-assigned managed identity
  |    +-- staging deployment slot + separate managed identity
  +-- Key Vault + RBAC
  +-- Private Endpoint + Private DNS
  +-- Log Analytics Workspace
  +-- Application Insights
  +-- Azure Monitor 5xx + response-time alerts
```

## Engineering goals

- Keep application-to-Azure authentication credential-free with managed identity.
- Keep Key Vault off the public network path and resolve it through Private Link.
- Separate ingress concerns from outbound VNet integration instead of treating them as the same control.
- Centralize application/platform telemetry in Log Analytics and Application Insights.
- Alert on production-facing service symptoms with configurable thresholds and external notification routing.
- Use reusable Terraform modules and environment-level composition rather than copy/paste infrastructure.
- Validate Terraform formatting, syntax, linting, and IaC security in pull requests without touching live state.
- Use GitHub OIDC for deployment identity rather than long-lived Azure client secrets.
- Separate release validation from production traffic cutover with an App Service staging slot.

## Structure

```text
azure-app-service-platform-reference/
├── terraform/
│   ├── modules/
│   │   └── platform/
│   └── environments/
│       └── dev/
├── docs/
│   ├── architecture.md
│   ├── deployment-identity.md
│   ├── deployment-slots.md
│   ├── monitoring-alerting.md
│   └── state-management.md
└── README.md
```

## Release model

The staging deployment slot provides a controlled promotion boundary: deploy to staging, validate the candidate, approve the change, then swap staging into production. Because the slot has its own managed identity, its Key Vault access is explicit rather than inherited by assumption.

See [`docs/deployment-slots.md`](docs/deployment-slots.md) for promotion, rollback, identity, networking, and configuration tradeoffs.

## Monitoring model

Azure Monitor metric alerts cover production HTTP 5xx volume and average response time. Thresholds are configurable and notification routing is supplied through existing Action Group IDs so the reusable module does not invent contacts or paging integrations.

See [`docs/monitoring-alerting.md`](docs/monitoring-alerting.md) for threshold ownership, alert limitations, routing, and production refinements.

## Scope boundaries

This is a portfolio reference implementation. It does not claim that the infrastructure has been applied to a production Azure subscription, that real traffic has been served, or that measured reliability/cost outcomes were achieved.

The project deliberately remains single-region and small. Front Door/WAF, multi-region DR, and broader release automation should only be added when they demonstrate a distinct operational decision rather than more boilerplate.
