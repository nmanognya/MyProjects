# Jenkins Container Delivery Reference

A small production-style Jenkins delivery example that shows how to test, build, scan, smoke-test, and publish one immutable container artifact without coupling the build pipeline to a specific deployment platform.

## What this demonstrates

- Declarative Jenkins Pipeline with bounded execution, build retention, and concurrency control
- isolated registry credentials using Jenkins Credentials Binding
- commit-SHA image tagging and registry digest capture after push
- Trivy HIGH/CRITICAL image vulnerability gate
- unit tests plus a live container smoke test with bounded retries
- a non-root container image with a health check
- separation between artifact publication and downstream environment promotion
- read-only GitHub Actions validation for the portfolio implementation

## Architecture

```text
Git commit
   |
   v
Jenkins checkout
   |
   +--> Python compile + unit tests
   |
   +--> Docker build: <repository>:<git-sha>
   |
   +--> Trivy image gate
   |
   +--> Run same image + /healthz smoke test
   |
   +--> main + explicit PUBLISH_IMAGE only
              |
              v
      Scoped registry credentials
              |
              v
          OCI registry
              |
              v
  release-metadata.txt
  commit=<sha>
  image=<repo>@sha256:<digest>
              |
              v
   downstream promotion/deployment
```

The important boundary is that Jenkins produces and records an immutable release candidate. It does not rebuild the image during promotion and it does not pretend to own runtime deployment policy.

## Repository structure

```text
jenkins-container-delivery-reference/
├── Jenkinsfile
├── Dockerfile
├── app/
│   ├── app.py
│   └── test_app.py
├── scripts/
│   └── smoke-test.sh
└── docs/
    └── release-model.md
```

## Jenkins prerequisites

The job should use Pipeline from SCM and a Jenkins worker with the `docker-linux` label. The worker needs:

- Python 3
- Docker CLI/daemon access
- curl
- Trivy

Create a Jenkins username/password credential with ID `container-registry` only if image publishing will be exercised. Do not add registry credentials to this repository.

For a real environment, the Docker-capable worker should be isolated and preferably short-lived because Docker daemon access is privileged. Controller and agent provisioning are intentionally outside this project's scope.

## Running locally

```bash
cd jenkins-container-delivery-reference/app
python -m compileall -q .
python -m unittest -v test_app.py

cd ..
docker build -t jenkins-delivery-reference:local .
container_id="$(docker run -d --rm -p 127.0.0.1::8080 jenkins-delivery-reference:local)"
host_port="$(docker inspect --format='{{(index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' "$container_id")"
./scripts/smoke-test.sh "http://127.0.0.1:${host_port}/healthz"
docker stop "$container_id"
```

## Release behavior

Normal pull request and branch builds stop after test, build, scan, and smoke validation. Publication occurs only when both conditions are true:

- Jenkins is building `main`
- `PUBLISH_IMAGE=true` was explicitly selected

The publish stage logs into the target registry inside a narrow credentials scope, pushes the already-tested commit-SHA image, resolves the registry digest, and archives the commit-to-digest mapping as fingerprinted build metadata.

See [docs/release-model.md](docs/release-model.md) for trust boundaries, failure behavior, rollback, and agent risks.

## Security and reliability decisions

The container runs as UID 10001, exposes only the application port, and has an OCI health check. Pipeline timeouts and bounded smoke retries prevent indefinitely stuck builds. HIGH/CRITICAL Trivy findings fail before publication. Credentials are not made global pipeline environment variables.

The reference intentionally does not claim that a registry enforces tag immutability, that images are signed, or that any workload was deployed to production. Those controls depend on the external registry and runtime platform.

## Limitations and next improvements

This is a focused delivery reference, not a Jenkins platform installation. Useful next additions would be Jenkins Pipeline Unit tests for shared-library logic, ephemeral Kubernetes agents, or signed/provenance-attested image publication. They should be added only if they remain distinct from the existing GitOps and EKS portfolio projects.
