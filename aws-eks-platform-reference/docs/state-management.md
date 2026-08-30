# Terraform State Management

This project uses an S3 backend declaration and keeps environment-specific backend values outside Terraform source files. The checked-in `backend.hcl.example` documents the expected shape without committing an account-specific bucket name or credentials.

## Initialize remote state

Copy the example to a local file that remains outside version control, replace the placeholder bucket name, then initialize Terraform:

```bash
cd terraform/environments/dev
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
```

AWS credentials should come from the normal AWS credential chain, preferably an assumed role or CI workload identity. Do not put access keys, session tokens, or other credentials in backend configuration files.

## State locking

The S3 backend is configured with `use_lockfile = true`. Terraform creates a `.tflock` object alongside the state while an operation holds the lock. This prevents concurrent writers from modifying the same state at the same time.

The identity running Terraform needs access to the state object and lock file. Keep permissions scoped to the environment-specific state prefix rather than granting broad access to the entire bucket where possible.

A minimal policy pattern should allow:

- `s3:ListBucket` only for the required state prefix.
- `s3:GetObject` and `s3:PutObject` for the state object.
- `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` for the `.tflock` object.

Deleting the state object itself should not be part of the normal Terraform execution role.

## Recovery controls

The backend bucket should be provisioned separately from the infrastructure whose state it stores. Recommended controls include:

1. Enable S3 Versioning so previous state object versions can be recovered after accidental overwrite or deletion.
2. Block public access at the bucket level.
3. Require server-side encryption and restrict KMS key access if a customer-managed key is used.
4. Separate production state permissions from lower environments.
5. Keep CloudTrail data events or equivalent audit coverage when stronger state-access auditing is required.

If state is damaged or an incorrect object version is written, restore the known-good S3 object version before running another Terraform apply. Review the restored state with `terraform state list`, `terraform plan`, and the expected infrastructure inventory before making changes.

## Lock recovery

Do not remove a lock simply because a Terraform command appears slow. First confirm that no active Terraform process or CI job still owns it.

If the process that created the lock is definitively gone, use Terraform's lock recovery workflow rather than manually deleting state data. Record the reason for the unlock in operational notes or the relevant change record.

## CI behavior

Pull-request CI runs `terraform init -backend=false` because validation and static security scanning do not need access to live state. Apply workflows should be separate, authenticated, environment-scoped, and protected by appropriate review controls.

This repository demonstrates the backend pattern only. It does not create or operate a real shared state bucket.
