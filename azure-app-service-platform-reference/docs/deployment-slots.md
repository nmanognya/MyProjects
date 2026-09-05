# App Service deployment slots

This reference uses a dedicated `staging` deployment slot so application releases can be exercised before production traffic is switched.

## Why the slot exists

Deploying directly to the production slot couples artifact deployment and traffic cutover into one step. A staging slot separates those concerns:

1. deploy the candidate artifact to `staging`;
2. validate health and application behavior against the staging hostname;
3. swap staging into production only after validation and approval;
4. use the previous production content now in `staging` as the immediate rollback candidate if the release regresses.

A slot swap is a release-control mechanism, not a replacement for application-level rollback planning. Schema migrations, external side effects, and incompatible data changes still require explicit backwards-compatibility or migration strategy.

## Identity and secret access

The production web app and staging slot each receive their own system-assigned managed identity. Both identities get the narrowly scoped `Key Vault Secrets User` role on this reference Key Vault.

Keeping separate principals makes the trust boundary visible and avoids assuming that a slot automatically shares the production slot's identity. In a stricter environment, staging and production could use different vaults or different secret scopes.

No application credentials are committed to Terraform or GitHub Actions.

## Network behavior

The staging slot uses the same delegated App Service VNet-integration subnet as production. Key Vault remains reachable through the existing Private Endpoint and private DNS zone.

This design intentionally reuses the integration subnet because both slots are part of the same application platform. A larger platform may separate release-test traffic or dependencies when stronger blast-radius isolation is required.

## Promotion flow

A production-style pipeline should follow this sequence:

```text
build immutable artifact
        |
        v
deploy artifact to staging slot
        |
        v
health / smoke / integration checks
        |
        v
manual or policy approval
        |
        v
swap staging -> production
        |
        v
post-swap validation
```

The infrastructure PR does not claim that an application artifact has been deployed or that a live slot swap has occurred.

## Rollback

After a successful swap, the previous production version resides in the staging slot. If post-swap validation detects a regression that is safe to reverse, swapping the slots again provides a fast content rollback.

Rollback should not be automatic for every failed signal. Operators need to consider:

- database or API compatibility;
- irreversible external writes;
- whether the failure is caused by configuration rather than application code;
- whether swapping back would make the incident worse.

## Configuration caveat

Some App Service settings can be marked as slot-specific so they do not move during a swap. This reference currently keeps the Application Insights connection string common between slots to keep the example small. Real environments should explicitly classify settings as shared or slot-sticky before enabling production promotion.

## Cost and limitations

Deployment slots run on the same App Service Plan, so they consume plan capacity. Slot support and available slot count also depend on the selected App Service Plan tier.

This repository demonstrates the infrastructure and release design only. It does not claim live Azure traffic, measured swap duration, uptime, or production rollback performance.
