# Validated slot promotion

The release workflow separates candidate validation from production traffic cutover. It assumes an application artifact has already been deployed to the `staging` App Service slot; the workflow promotes that existing candidate rather than rebuilding it.

## Promotion flow

1. An operator starts `Azure App Service Slot Promotion` with the target resource group and App Service name.
2. The workflow requires the literal confirmation `PROMOTE`.
3. The `azure-dev` GitHub Environment is entered before Azure access. Configure required reviewers and deployment-branch restrictions on that environment so the approval is enforced outside workflow YAML.
4. GitHub exchanges its OIDC token for a short-lived Microsoft Entra token through `azure/login`; no Azure client secret is stored in the repository.
5. The workflow resolves the staging slot hostname and runs `scripts/smoke-test.sh`.
6. Only a passing staging smoke test allows `staging` to swap into `production`.
7. The production hostname is then smoke-tested with the same contract.
8. If production validation fails, the workflow attempts the same slot swap again to restore the previous production slot content, then fails the run so an operator must investigate.

## Smoke-test contract

The smoke helper uses bounded retries and timeouts. A response must return HTTP 2xx. An optional literal response string can also be required when a status code alone is too weak to prove that the intended application is running.

The check is intentionally small. A real service should replace or extend it with a stable health endpoint that verifies only dependencies required to serve traffic. Deep destructive tests do not belong in this pre-promotion path.

## Rollback boundary

A slot swap reverses App Service slot content and swappable configuration. It does **not** reverse external side effects such as database migrations, queue messages, third-party calls, or schema changes. Release design must therefore keep backward compatibility across the promotion window or use an independently reversible migration strategy.

The automated swap-back is best-effort. If Azure rejects the second swap or the application remains unhealthy, the workflow still fails and operators must inspect both slots and any external state before retrying.

## Identity and authorization

The workflow uses the same GitHub OIDC variables as the Terraform deployment workflow:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

The federated Azure identity should receive only the permissions required to read the target App Service/slot and perform slot swaps. Broad subscription-level `Contributor` access is unnecessary for this release operation.

The `azure-dev` environment should protect the federated credential path with required reviewers and branch restrictions. `id-token: write` only allows GitHub to request an OIDC token; Azure RBAC still determines what the exchanged token can change.

## Concurrency

The workflow uses a fixed environment-specific concurrency group with `cancel-in-progress: false`. This prevents two promotions from racing against the same production slot while preserving an already-running release rather than cancelling it midway through a swap.

## What this demonstrates

This reference shows a production-style release boundary: build/deploy a candidate separately, validate it before traffic, require an approval boundary, promote without rebuilding, verify production, and have a bounded rollback action. It does not claim that a live Azure deployment or production slot swap has been executed from this repository.
