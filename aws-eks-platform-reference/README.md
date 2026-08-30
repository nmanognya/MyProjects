# AWS EKS Platform Reference

A production-style portfolio reference architecture demonstrating how to provision and operate a small Amazon EKS platform using Terraform, Kubernetes, Helm, and GitHub Actions.

## Goals

- Provision repeatable AWS infrastructure with Terraform.
- Separate networking and EKS concerns into reusable modules.
- Deploy a containerized demo service with Helm.
- Demonstrate health checks, resource controls, autoscaling, and disruption protection.
- Validate infrastructure and application changes automatically in CI.
- Document security, reliability, observability, rollback, cost, and troubleshooting considerations.

## Current foundation

The Terraform layer includes multi-AZ VPC networking, configurable NAT topology, private EKS worker nodes, private-by-default Kubernetes API access, EKS control-plane logging, KMS envelope encryption for Kubernetes Secrets, managed node-group scaling, S3 remote-state configuration, EKS Pod Identity, and CI validation/security gates.

The workload is a small Flask service with dedicated liveness/readiness endpoints and real Prometheus request-count and request-latency metrics. Its container runs as an unprivileged UID behind Gunicorn, and application CI runs unit tests, builds the image, generates an SPDX SBOM, and scans the image with Trivy.

The Helm workload layer demonstrates a hardened non-root deployment, readiness/liveness probes, resource requests and limits, rolling-update controls, a PodDisruptionBudget, CPU-based HPA behavior, a dedicated ServiceAccount with token automount disabled, strict Helm linting, manifest rendering, Conftest/Rego policy enforcement, and Trivy configuration scanning.

Environment-specific Helm overlays model dev, staging, and production release behavior without duplicating the chart. CI renders and scans every overlay. The chart supports digest-pinned images, and the production overlay requires a SHA-256 digest so a moved tag cannot silently change the reviewed production artifact. Deployment uses Helm atomic/wait controls and post-deployment smoke checks; a separate rollback helper restores an explicit Helm revision.

The demo workload identity maps the `default/platform-demo` ServiceAccount to a dedicated IAM role and limits `cloudwatch:PutMetricData` to the `Portfolio/EKSPlatformDemo` custom metric namespace. No static AWS credentials are committed or mounted into the workload.

The observability layer can optionally create a Prometheus Operator `ServiceMonitor` for the application's `/metrics` endpoint and `PrometheusRule` resources for platform-level availability/restart signals plus application SLO recording and burn-rate alerts. The example uses real HTTP request/error/latency metrics, but makes no claim that the portfolio workload has achieved a production SLO.

Operational design notes:

- [Networking and egress tradeoffs](./docs/networking.md)
- [Terraform state management, locking, and recovery](./docs/state-management.md)
- [Workload reliability, scaling, and security controls](./docs/workload-reliability.md)
- [EKS Pod Identity and least-privilege workload AWS access](./docs/workload-identity.md)
- [Prometheus platform alerting, dependencies, and limitations](./docs/observability.md)
- [Application metrics and ServiceMonitor design](./docs/application-observability.md)
- [SLO objectives, error-budget math, and burn-rate alerts](./docs/slo-error-budget.md)
- [Release promotion, deployment safety, and rollback strategy](./docs/release-strategy.md)
- [Container SBOM, digest pinning, and provenance](./docs/supply-chain.md)
- [Kubernetes policy-as-code controls and enforcement boundary](./docs/policy-as-code.md)

## Project structure

```text
aws-eks-platform-reference/
├── app/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── test_app.py
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   ├── eks/
│   │   └── workload-identity/
│   └── environments/
│       └── dev/
├── helm/
│   └── platform-demo/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       └── templates/
├── policy/
│   ├── kubernetes/
│   └── fixtures/
├── scripts/
│   ├── deploy-helm.sh
│   ├── rollback-helm.sh
│   ├── smoke-test.sh
│   └── verify-release-attestation.sh
├── docs/
└── README.md
```

## Engineering principles

This repository is a portfolio project and reference architecture. It does not claim to represent a live customer production environment. The design favors explicit engineering tradeoffs, reproducibility, least privilege, secure defaults, automation, and operational readiness.

## Next implementation slice

This EKS reference is approaching a sensible stopping point. After the policy gate is validated, the next highest-value portfolio addition is a separate Azure or GitOps-focused project rather than continuing to expand this one indefinitely.
