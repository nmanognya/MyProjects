# Container supply-chain controls

This project treats the application image as a release artifact rather than as an interchangeable tag.

## Current controls

### SBOM in CI

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

Development and staging may still use explicit tags for convenience, although digest promotion is preferred once a registry-backed release pipeline exists.

## Intended release flow

A complete registry-backed implementation should follow this sequence:

1. Build the container image once.
2. Run tests and vulnerability scanning against that image.
3. Generate the SBOM from the built image.
4. Push the image to the approved registry.
5. Capture the registry-provided `sha256` manifest digest.
6. Generate build provenance and SBOM attestations for the pushed digest.
7. Promote that same digest through staging and production.
8. Verify provenance before admission or deployment when an enforcement mechanism is available.

This repository does not currently claim steps 4, 6, or 8. They require an intentional registry/release identity and an attestation-verification policy.

## Why attestations are not generated on every PR

PR CI builds disposable validation images. Signing or attesting every test image creates evidence for artifacts that are never released. Provenance is most useful when attached to the artifact consumers will actually deploy and when consumers verify that provenance.

A future release workflow can use GitHub artifact attestations after an image is pushed and its registry digest is known. GitHub's attestation flow supports container-image provenance and SBOM attestations, and Kubernetes admission enforcement can be added later if the cluster policy requires it.

## Tradeoffs and limitations

- An SBOM improves component visibility but does not establish artifact authenticity.
- Digest pinning establishes artifact identity but does not prove that the build process was trustworthy.
- Attestations add provenance evidence but only create security value when verification policy is enforced.
- Registry publication needs write permissions; those permissions should live only in a dedicated release workflow, not ordinary PR validation.
- Digest pinning means each production rollout needs an explicit new digest, which is intentional change control rather than operational friction.

## Example production deployment

```bash
./scripts/deploy-helm.sh prod sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The example digest is illustrative only and is not claimed to exist in a registry.
