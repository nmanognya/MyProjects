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

The Terraform layer includes multi-AZ VPC networking, configurable NAT topology, private EKS worker nodes, private-by-default Kubernetes API access, EKS control-plane logging, KMS envelope encryption for Kubernetes Secrets, managed node-group scaling, S3 remote-state configuration, and CI validation/security gates.

The Helm workload layer now demonstrates a hardened non-root deployment, readiness/liveness probes, resource requests and limits, rolling-update controls, a PodDisruptionBudget, CPU-based HPA behavior, a dedicated ServiceAccount with token automount disabled, strict Helm linting, manifest rendering, and Trivy configuration scanning.

Operational design notes:

- [Networking and egress tradeoffs](./docs/networking.md)
- [Terraform state management, locking, and recovery](./docs/state-management.md)
- [Workload reliability, scaling, and security controls](./docs/workload-reliability.md)

## Project structure

```text
aws-eks-platform-reference/
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   └── eks/
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

Add workload identity with least-privilege AWS permissions, then add application/platform observability and controlled deployment/rollback examples.
