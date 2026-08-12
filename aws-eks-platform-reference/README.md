# AWS EKS Platform Reference

A production-style portfolio reference architecture demonstrating how to provision and operate a small Amazon EKS platform using Terraform, Kubernetes, Helm, and GitHub Actions.

## Goals

- Provision repeatable AWS infrastructure with Terraform.
- Separate networking and EKS concerns into reusable modules.
- Deploy a containerized demo service with Helm.
- Demonstrate health checks, resource controls, autoscaling, and disruption protection.
- Validate infrastructure and application changes automatically in CI.
- Document security, reliability, observability, rollback, cost, and troubleshooting considerations.

## Planned Structure

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

## Engineering Principles

This repository is a portfolio project and reference architecture. It does not claim to represent a live customer production environment. The design favors explicit engineering tradeoffs, reproducibility, least privilege, secure defaults, automation, and operational readiness.

## Status

Initial project scaffolding is in progress.
