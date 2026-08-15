# Networking Design

This project uses public and private subnets across multiple Availability Zones. EKS managed nodes are placed in private subnets. Public subnets exist for internet-facing load balancers and NAT gateways, but they do not automatically assign public IP addresses.

## Private subnet egress

The networking module exposes `nat_gateway_mode` with three explicit choices:

| Mode | Behavior | Availability | Cost profile | Intended use |
|---|---|---|---|---|
| `none` | No default internet route from private subnets | No NAT dependency | Lowest | Fully private environments using VPC endpoints or intentionally isolated workloads |
| `single` | All private subnets route through one NAT gateway in the first public subnet | NAT/AZ dependency and possible cross-AZ data path | Lower than per-AZ | Development, demos, and cost-sensitive non-production environments |
| `per_az` | Each private subnet routes through a NAT gateway in the corresponding AZ | Better AZ isolation | Highest | Production-style environments where resilience justifies additional NAT cost |

The default remains `none` so enabling paid internet egress is an explicit decision.

## Why private route tables are per subnet

Each private subnet receives its own route table. That makes the `per_az` topology deterministic and avoids a shared route table silently sending traffic to a NAT gateway in another Availability Zone.

With `single`, those route tables intentionally point to the same NAT gateway. This keeps the configuration easy to promote later from a cost-oriented topology to a per-AZ topology without redesigning route-table ownership.

## NAT gateways vs. VPC endpoints

NAT gateways are simple for arbitrary outbound internet access, including package repositories and third-party APIs, but they add hourly and data-processing charges and can introduce cross-AZ transfer when a single NAT serves several AZs.

VPC endpoints can reduce NAT dependency for AWS services such as S3, ECR, CloudWatch, STS, and Systems Manager. They also keep service traffic on the AWS network. The tradeoff is additional endpoint configuration, endpoint-specific costs for interface endpoints, and more DNS/security-policy surface to operate.

A mature production environment often uses both: VPC endpoints for heavily used AWS services and NAT gateways only for traffic that genuinely requires internet egress.

## Secure defaults

- EKS worker nodes use private subnets.
- Public subnet instances do not receive public IP addresses automatically.
- NAT is disabled unless an environment opts in.
- Public exposure is expected to occur through explicitly configured load balancers rather than subnet defaults.
- No account-specific addresses, gateway IDs, or credentials are committed.

## Failure considerations

### `single`

If the NAT gateway or its Availability Zone becomes unavailable, outbound internet connectivity from all private subnets is affected. Workloads that depend on external APIs, image downloads, or package repositories can be impacted even when their own AZ remains healthy.

### `per_az`

A NAT gateway failure primarily affects private subnets in the same AZ. This improves fault isolation but increases recurring infrastructure cost.

### `none`

Workloads have no general internet egress. Required AWS APIs must be reachable through appropriate VPC endpoints, and any third-party outbound dependency requires a separate approved egress design.

## Example

```hcl
module "networking" {
  source = "../../modules/networking"

  name                 = "portfolio-dev"
  vpc_cidr             = "10.20.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

  # Use "single" for a cost-oriented dev environment or "per_az"
  # for stronger AZ isolation.
  nat_gateway_mode = "single"
}
```

This repository is a production-style reference implementation. It does not claim these resources are deployed to or operating a live production AWS environment.
