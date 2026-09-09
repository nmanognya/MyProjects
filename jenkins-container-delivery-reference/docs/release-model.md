# Release model

This reference separates CI validation from artifact publication. Pull requests can compile and test the service, build the container, run a vulnerability gate, and smoke-test the image without receiving registry credentials. Publication is allowed only for `main` builds when `PUBLISH_IMAGE=true` is explicitly selected.

## Build-once artifact flow

1. Checkout the exact Jenkins SCM revision.
2. Run Python compilation and unit tests.
3. Build one image tagged with the Git commit SHA.
4. Fail on HIGH or CRITICAL Trivy findings before publication.
5. Start that same local image and exercise `/healthz` with bounded retries.
6. On an explicitly requested `main` release, authenticate to the OCI registry only inside the publish stage.
7. Push the tested SHA-tagged image and capture the registry-provided digest in `release-metadata.txt`.
8. Fingerprint and archive the metadata so downstream promotion can consume an immutable image reference rather than rebuilding source.

The pipeline intentionally stops at artifact publication. Environment deployment belongs in a separate delivery control such as Argo CD, a deployment job, or a release pipeline. This avoids coupling image creation to one runtime and prevents a production promotion from silently rebuilding the artifact.

## Jenkins controls

- `disableConcurrentBuilds()` prevents two builds of this job from contending for the same workspace or release operation.
- A 30-minute pipeline timeout bounds stuck agents and external commands.
- Build retention limits controller storage growth.
- Registry credentials are injected only for the publish stage through Jenkins Credentials Binding and are never stored in the repository.
- `docker login --password-stdin` avoids placing the password directly on the command line.
- The pipeline logs out after publication and removes the local image in `post { always { ... } }`.
- Publication is both branch-gated and opt-in. Pull requests do not get a release path from this Jenkinsfile.

## Agent assumptions

The `docker-linux` Jenkins agent label represents an administrator-managed worker with Python, Docker, curl, and Trivy installed. A real Jenkins platform should make the agent image or VM configuration immutable and versioned; this repository does not claim to provision the Jenkins controller or worker fleet.

Docker socket access is security-sensitive because it is effectively host-level privilege. Production Jenkins installations should isolate build workers, use short-lived agents where possible, restrict who can modify trusted pipelines, and avoid co-locating untrusted workloads on the same Docker daemon.

## Failure and rollback boundaries

A failed unit test, image build, vulnerability scan, or smoke test prevents publication. A registry push failure also fails the build and no release metadata is archived.

Artifact publication itself does not change a runtime environment, so rollback is handled by downstream deployment tooling selecting an earlier known-good digest. The archived `commit` and `image` fields provide the handoff needed for that decision.

This reference does not claim registry immutability policy, signed images, admission enforcement, deployment success, production traffic, or recovery-time outcomes. Those controls require infrastructure outside this small Jenkins example.
