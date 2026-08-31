# Architecture decisions

## Managed PaaS instead of another Kubernetes project

App Service is used deliberately so the portfolio demonstrates a different platform tradeoff from EKS. Azure owns more of the runtime control plane, while the platform engineer still owns identity, networking, configuration, observability, release policy, and cost/reliability decisions.

## Identity

The web app uses a system-assigned managed identity. Application code should request Azure tokens at runtime and access services through RBAC rather than receive stored cloud credentials.

GitHub Actions is designed around Azure workload identity federation. The repository should not require a client secret for CI/CD.

## Network model

Two subnet roles are separated:

- **Integration subnet:** delegated to App Service for outbound VNet integration.
- **Private endpoint subnet:** hosts private endpoints for services such as Key Vault.

This distinction matters because App Service VNet integration controls outbound connectivity from the application; it does not itself make the web app private.

Key Vault public network access is disabled in the reference design. Its private endpoint is associated with the `privatelink.vaultcore.azure.net` private DNS zone so the application resolves the vault to a private address through the VNet.

## Secret access

The web app identity receives only the Key Vault Secrets User data-plane role. Infrastructure identities and application identities should remain separate. No example secret value is committed to this repository.

## Observability

Application Insights is backed by a Log Analytics workspace. This keeps application telemetry queryable alongside Azure platform diagnostics while avoiding claims about live production dashboards or alert history.

## Availability and DR

The first iteration is single-region. App Service's managed platform reduces host-management work but does not eliminate regional failure risk. A later DR design could use a second region plus Front Door, duplicated private dependencies, and tested recovery procedures. That is intentionally documented rather than prematurely implemented.

## Cost

Private Endpoints, Log Analytics ingestion, Application Insights telemetry, and higher App Service tiers all add cost. The project keeps these controls explicit so an interviewer can see where security, availability, and cost interact.
