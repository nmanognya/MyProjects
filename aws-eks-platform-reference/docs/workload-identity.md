# Workload Identity and AWS Access

The demo workload uses **Amazon EKS Pod Identity** to obtain short-lived AWS credentials through its Kubernetes ServiceAccount. No static AWS access keys are stored in Kubernetes Secrets, Helm values, Terraform variables, or GitHub Actions.

## Design

The Terraform implementation installs the `eks-pod-identity-agent` add-on and creates a reusable workload-identity module that associates the `default/platform-demo` ServiceAccount with a dedicated IAM role.

The IAM role trust policy is restricted to:

- EKS cluster `portfolio-eks-dev`
- Kubernetes namespace `default`
- ServiceAccount `platform-demo`

EKS Pod Identity session tags provide those workload attributes during role assumption. This prevents another namespace or ServiceAccount from using the role even if it knows the role ARN.

## Least-privilege example

The role has one application permission:

```text
cloudwatch:PutMetricData
```

`PutMetricData` does not support resource-level ARNs, so the policy resource must be `*`. The policy compensates by using the `cloudwatch:namespace` condition key and permits publishing only to:

```text
Portfolio/EKSPlatformDemo
```

This demonstrates a realistic least-privilege boundary for a workload that may later publish custom application metrics without granting CloudWatch read, alarm-management, log, or broader AWS permissions.

## Credential path

1. The Pod runs with the `platform-demo` ServiceAccount.
2. EKS recognizes the Pod Identity association.
3. The Pod Identity Agent running on the node provides temporary credentials to a supported AWS SDK credential chain.
4. AWS STS assumes the dedicated workload IAM role.
5. IAM limits the session to the role policy and its CloudWatch namespace condition.

The application should use the default AWS SDK credential provider chain. Credentials are temporary and rotated by the EKS Pod Identity mechanism.

## Operational considerations

- The Pod Identity Agent is a cluster dependency for workloads using this mechanism.
- Pod Identity associations and IAM changes are eventually consistent; deployment automation should not assume a new association is usable immediately.
- The workload currently does not publish custom metrics. The permission is intentionally narrow plumbing for the next observability slice, not a claim that metrics are already emitted.
- Restrict node access to the EC2 Instance Metadata Service so a compromised Pod cannot fall back to node-role credentials.
- Keep application IAM separate from the managed-node IAM role. Adding workload permissions to the node role would expose those permissions to every Pod able to obtain node credentials.
- Each ServiceAccount can have only one direct Pod Identity role association in a cluster, so permissions for that workload should stay cohesive and minimal.

## Why Pod Identity instead of IRSA

Both mechanisms can provide pod-level IAM permissions. This reference architecture uses EKS Pod Identity because it avoids per-cluster OIDC provider configuration and keeps the ServiceAccount free of IAM-role annotations. The IAM trust is established with the EKS Pod Identity service principal and the EKS API owns the ServiceAccount-to-role association.

IRSA remains relevant for environments where Pod Identity is unavailable or where existing platform standards already depend on OIDC-based trust.
