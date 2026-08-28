# Container supply-chain controls

This project treats the application image as a release artifact rather than as an interchangeable tag.

## Current controls

### SBOM in PR CI

Application CI builds the same local container image that is scanned by Trivy and generates an SPDX JSON software bill of materials (SBOM) from that image. The SBOM is retained as a workflow artifact for review and troubleshooting.

The SBOM is evidence about image contents; it is not a signature and does not prove who built the image.

### Digest-aware Helm deployment

The Helm chart supports either a tag or a registry digest:

```yaml
image:
  repository: ghcr.io/nmanognya/platform-demo
  tag: "example"
  digest: ""
  requireDigest: false
```

When `image.digest` is set, Kubernetes receives an image reference such as:

```text
ghcr.io/nmanognya/platform-demo@sha256:<digest>
```

A digest identifies exact registry content. Reusing or moving a human-readable tag therefore cannot silently change the artifact referenced by an already-reviewed production deployment.

### Production policy

`values-prod.yaml` sets `image.requireDigest: true`. The deployment helper also rejects production promotion unless the supplied image reference matches a SHA-256 digest.

Helm CI includes a negative policy test proving that production rendering fails without a digest, then supplies an illustrative validation digest so the rendered production manifests can still be linted and security-scanned. The validation digest is never published or presented as a real artifact.

Development and staging may still use explicit tags for convenience, although digest promotion is preferred for released artifacts.

### Registry-backed release workflow

`.github/workflows/aws-eks-release.yml` is an intentionally separate, manually dispatched release boundary. It requires an explicit release version and a positive publish confirmation before it receives package-write and attestation permissions.

The workflow is designed to:

1. Build the application image once.
2. Push that image once to `ghcr.io/nmanognya/platform-demo`.
3. Capture the registry-provided manifest digest from the build/push step.
4. Generate an SPDX JSON SBOM from the published digest.
5. Attach GitHub build-provenance and SBOM attestations to that same digest in the registry.
6. Write the exact digest into the workflow summary for downstream environment promotion.

Normal pull-request CI remains read-only and cannot publish packages.

The presence of this workflow demonstrates release design; this portfolio does not claim that a GHCR package or attestation has actually been published unless a release run is executed successfully.

## Build once, promote by digest

The intended promotion path is:

```text
source commit
    |
    v
release workflow
    |
    +--> build/test image
    +--> push GHCR tag
    +--> capture sha256 digest
    +--> generate SBOM
    +--> attach provenance + SBOM attestations
    |
    v
dev -> staging -> production
        same sha256 digest
```

The artifact is not rebuilt between environments. Environment-specific Helm configuration changes around the artifact, while the image identity stays constant.

## Why attestations are not generated on every PR

PR CI builds disposable validation images. Attesting every test image creates evidence for artifacts that are never released and would require unnecessary write permissions in an untrusted review path.

The dedicated release workflow generates attestations only after the deployable artifact has a registry digest. Consumers can later verify those attestations before deployment or through an admission policy.

## Verification and admission boundary

Build provenance is useful only when a consumer verifies it. A production extension could verify the GHCR image with GitHub CLI before deployment or enforce provenance in Kubernetes with an admission controller.

Admission enforcement is intentionally not enabled in this reference project yet. Adding enforcement without a live cluster trust policy, exception process, and recovery path would create the appearance of security without showing how the policy is operated.

## Tradeoffs and limitations

- An SBOM improves component visibility but does not establish artifact authenticity.
- Digest pinning establishes artifact identity but does not prove that the build process was trustworthy.
- Attestations add provenance evidence, but their security value depends on verification policy.
- Registry publication needs write permissions; those permissions live only in the dedicated release workflow, not ordinary PR validation.
- A manually dispatched release makes the trust boundary easy to review but still requires operator discipline around version selection.
- Digest pinning means each production rollout needs an explicit new digest, which is intentional change control rather than operational friction.
- This portfolio does not claim a published GHCR image, successful attestation, or admission enforcement until those operations have actually run.

## Example production deployment

```bash
./scripts/deploy-helm.sh prod sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The example digest is illustrative only and is not claimed to exist in a registry.
