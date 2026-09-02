# GitHub OIDC deployment boundary

The deployment workflow uses GitHub Actions OpenID Connect (OIDC) to obtain short-lived Microsoft Entra credentials for Terraform. No Azure client secret is stored in the repository or workflow.

## Trust model

The workflow requires these GitHub variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TFSTATE_RESOURCE_GROUP`
- `AZURE_TFSTATE_STORAGE_ACCOUNT`
- `AZURE_TFSTATE_CONTAINER`

The Entra application/service principal should have a federated credential constrained to this repository and the intended GitHub environment or workflow subject. The Azure role assignment should be scoped only to the resource group(s) Terraform is expected to manage plus the minimum Blob data-plane permissions required for the Terraform state container.

Do not grant subscription-level `Owner` or `Contributor` merely to make the example easier to run.

## Plan/apply separation

`.github/workflows/azure-app-service-terraform-deploy.yml` is manual by design.

1. The `plan` job authenticates with OIDC, initializes the remote backend, and creates a binary Terraform plan plus a human-readable rendering.
2. If `operation=apply`, the workflow only proceeds when `confirm_apply` is exactly `APPLY`.
3. The `apply` job references the protected `azure-dev` GitHub Environment. Configure that environment with required reviewers and branch restrictions before using the workflow against a real Azure subscription.
4. The apply job downloads and applies the exact binary plan created earlier in the same workflow run, avoiding an unreviewed second plan between approval and apply.
5. Workflow concurrency serializes dev infrastructure changes so two applies cannot race for the same state.

## Plan artifact handling

Terraform binary plans can contain values derived from state and input variables, including sensitive values. This project therefore:

- retains the plan artifact for only one day;
- does not place application secrets in Terraform variables;
- keeps ordinary pull-request CI completely separate from this privileged workflow.

For a real organization, restrict repository/Actions access accordingly and use a dedicated secrets system rather than placing secret material into Terraform plan inputs.

## State authentication

The workflow creates `backend.hcl` only on the ephemeral runner and sets both `use_azuread_auth = true` and `use_oidc = true`. Backend identifiers are configuration metadata, not credentials. The backend file is never committed.

The same OIDC identity is exposed to the AzureRM provider through `ARM_USE_OIDC`, `ARM_CLIENT_ID`, `ARM_TENANT_ID`, and `ARM_SUBSCRIPTION_ID`.

## Failure and recovery behavior

- A failed plan never reaches the apply job.
- A rejected or unapproved GitHub Environment stops apply before Azure mutations occur.
- Azure Blob state locking protects against concurrent state writes; workflow concurrency adds an earlier serialization boundary.
- If apply partially fails, investigate the Azure resources and Terraform state before retrying. Do not blindly delete the lock or state file.
- State recovery procedures are documented separately in `state-management.md`.

## Limitations

This repository defines the workflow and trust boundaries but does not claim that an Entra federated credential, GitHub Environment approval rule, Azure role assignment, or live deployment has been configured. Those controls must exist in the target GitHub/Azure accounts before the workflow can safely perform a real apply.
