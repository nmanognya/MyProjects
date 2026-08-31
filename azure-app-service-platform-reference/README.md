# Azure App Service Platform Reference

A production-style Azure platform reference that demonstrates secure application hosting without Kubernetes. The project focuses on private networking, managed identity, Key Vault access, Azure Monitor, Terraform, and GitHub Actions using workload identity federation.

## Why this project exists

The AWS EKS reference demonstrates Kubernetes-heavy platform engineering. This project intentionally exercises a different operating model: a managed Azure PaaS platform with fewer cluster responsibilities and stronger emphasis on identity, network isolation, secretless application access, and platform observability.

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
  +-- Key Vault + RBAC
  +-- Private Endpoint + Private DNS
  +-- Log Analytics Workspace
  +-- Application Insights
```

## Engineering goals

- Keep application-to-Azure authentication credential-free with managed identity.
- Keep Key Vault off the public network path and resolve it through Private Link.
- Separate ingress concerns from outbound VNet integration instead of treating them as the same control.
- Centralize application/platform telemetry in Log Analytics and Application Insights.
- Use reusable Terraform modules and environment-level composition rather than copy/paste infrastructure.
- Validate Terraform formatting, syntax, linting, and IaC security in pull requests without touching live state.
- Use GitHub OIDC for deployment identity rather than long-lived Azure client secrets.

## Planned structure

```text
azure-app-service-platform-reference/
├── terraform/
│   ├── modules/
│   │   └── platform/
│   └── environments/
│       └── dev/
├── docs/
│   └── architecture.md
└── README.md
```

## Scope boundaries

This is a portfolio reference implementation. It does not claim that the infrastructure has been applied to a production Azure subscription, that real traffic has been served, or that measured reliability/cost outcomes were achieved.

The first iteration is deliberately small: one regional application platform, one environment composition, private Key Vault access, managed identity, and monitoring. Multi-region DR, Front Door/WAF, deployment slots, and release automation are later extensions only if they add interview value.
