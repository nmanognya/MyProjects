# Terraform state management

## Backend design

The dev composition declares an `azurerm` backend and keeps environment-specific backend values outside the Terraform configuration. Copy `terraform/environments/dev/backend.hcl.example` to a local ignored file or provide the same values from an approved CI configuration source.

Example initialization:

```bash
terraform -chdir=terraform/environments/dev init \
  -backend-config=backend.hcl
```

The backend stores state as an Azure Blob. The AzureRM backend supports state locking and consistency checking using Azure Storage's native capabilities, so a separate lock database is not required.

## Authentication

Use Microsoft Entra ID for state access. For GitHub Actions, the intended deployment boundary is workload identity federation/OIDC rather than a stored client secret. Backend configuration contains resource identifiers only; credentials must not be committed or passed as sensitive `-backend-config` values.

The deployment identity should receive only the data-plane permissions required to read and update the state container. State administration and application deployment permissions should be separated where practical.

## CI behavior

Pull-request CI deliberately runs:

```bash
terraform init -backend=false
```

This validates providers and local modules without authenticating to Azure or reading live state. A future plan/apply workflow can initialize the real backend only after OIDC authentication and environment approval are defined.

## Locking and concurrency

Terraform automatically locks state for operations that can write state when the backend supports locking. Do not disable locking to bypass contention. If a failed operation leaves a stale lock, first confirm that no other Terraform process is active. `terraform force-unlock <LOCK_ID>` should be treated as a recovery action, not normal workflow behavior.

Parallel applies against the same environment/state key should be prevented at the workflow level as well, for example with GitHub Actions concurrency controls. Backend locking is a final safety control, not a replacement for deployment serialization.

## Recovery

The storage account that hosts Terraform state should be provisioned separately from the workload state it stores. Protect it with Azure Storage recovery controls such as blob versioning and soft-delete according to the organization's recovery requirements.

Before any destructive manual state operation:

1. Stop automated writers for the environment.
2. Confirm the current lock owner/state.
3. Capture a state backup with `terraform state pull` when safe.
4. Prefer restoring a known storage version over manually editing state.
5. Use `terraform state push` only as an exceptional recovery procedure after validating lineage and serial expectations.

The portfolio does not claim that a live Azure state account or recovery exercise has been performed.

## State isolation

Each environment should use its own state key at minimum. Production environments may justify stronger isolation through separate subscriptions, storage accounts, resource groups, or deployment identities. The correct boundary depends on blast-radius and compliance requirements; copying one shared credential across environments is intentionally outside this design.
