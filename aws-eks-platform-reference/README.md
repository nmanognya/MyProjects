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

The Helm workload layer demonstrates a hardened non-root deployment, readiness/liveness probes, resource requests and limits, rolling-update controls, a PodDisruptionBudget, CPU-based HPA behavior, a dedicated ServiceAccount with token automount disabled, strict Helm linting, manifest rendering, and Trivy configuration scanning.

The demo workload identity maps the `default/platform-demo` ServiceAccount to a dedicated IAM role and limits `cloudwatch:PutMetricData` to the `Portfolio/EKSPlatformDemo` custom metric namespace. No static AWS credentials are committed or mounted into the workload.

Operational design notes:

- [Networking and egress tradeoffs](./docs/networking.md)
- [Terraform state management, locking, and recovery](./docs/state-management.md)
- [Workload reliability, scaling, and security controls](./docs/workload-reliability.md)
- [EKS Pod Identity and least-privilege workload AWS access](./docs/workload-identity.md)

## Project structure

```text
aws-eks-platform-reference/
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
│       └── templates/
├── docs/
└── README.md
```

## Engineering principles

This repository is a portfolio project and reference architecture. It does not claim to represent a live customer production environment. The design favors explicit engineering tradeoffs, reproducibility, least privilege, secure defaults, automation, and operational readiness.

## Next implementation slice

Add application/platform observability and alerting, then demonstrate a controlled deployment and rollback strategy.
