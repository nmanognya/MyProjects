# CI/CD identity and validation

## Pull request validation

PR validation is intentionally read-only. The workflow needs repository contents only and does not receive Azure credentials, package-write permissions, or an OIDC token.

The Terraform gate runs:

1. `terraform fmt -check -recursive`
2. backend-disabled initialization for the dev composition
3. `terraform validate`
4. TFLint
5. Trivy IaC scanning for HIGH/CRITICAL findings

`terraform init -backend=false` ensures CI can resolve providers and local modules without connecting to live state.

## Azure deployment identity

A future deployment workflow should use GitHub Actions OIDC with an Azure federated identity credential. The workflow should request `id-token: write` only in the deployment boundary and authenticate with a dedicated Azure identity whose RBAC is limited to the intended environment.

Long-lived Azure client secrets are deliberately outside the design.

## Environment separation

The first implementation includes only `dev`. Staging and production should be added when there is a genuine configuration or approval difference to demonstrate. Copying identical environment directories would add noise without showing an engineering decision.

## Apply boundary

This repository does not currently run `terraform apply`. Introducing apply should come with remote state, environment protection/approval, OIDC authentication, plan review, and documented rollback/recovery behavior rather than adding a privileged workflow prematurely.
