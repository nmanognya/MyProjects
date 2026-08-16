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

The Terraform layer currently includes multi-AZ VPC networking, configurable NAT topology, private EKS worker nodes, private-by-default Kubernetes API access, EKS control-plane logging, KMS envelope encryption for Kubernetes Secrets, managed node-group scaling, S3 remote-state configuration, and CI validation/security gates.

Operational design notes:

- [Networking and egress tradeoffs](./docs/networking.md)
- [Terraform state management, locking, and recovery](./docs/state-management.md)

## Project structure

```text
aws-eks-platform-reference/
├── app/
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   └── eks/
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── helm/
│   └── platform-demo/
├── docs/
├── scripts/
└── README.md
```

## Engineering principles

This repository is a portfolio project and reference architecture. It does not claim to represent a live customer production environment. The design favors explicit engineering tradeoffs, reproducibility, least privilege, secure defaults, automation, and operational readiness.

## Next implementation slice

Add a Helm-managed Kubernetes workload with readiness/liveness probes, resource requests and limits, PodDisruptionBudget, and HorizontalPodAutoscaler configuration.
