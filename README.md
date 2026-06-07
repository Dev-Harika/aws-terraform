# AWS Infrastructure — Terraform

Production-grade AWS infrastructure as code using reusable Terraform modules.
Demonstrates 6+ years of Terraform/DevOps experience with real-world patterns
used in platform engineering: multi-environment separation, remote state,
IRSA for pod-level AWS access, and automated CI/CD via GitHub Actions.

![CI](https://github.com/Dev-Harika/aws-terraform/actions/workflows/terraform.yml/badge.svg)

## Architecture

```
environments/
├── dev/    ← 2-AZ, spot nodes, single NAT, no deletion protection
└── prod/   ← 3-AZ, on-demand + spot, per-AZ NAT, Multi-AZ RDS, flow logs

modules/
├── vpc/        ← Multi-AZ VPC, public/private subnets, NAT gateway, flow logs
├── eks/        ← EKS cluster, managed node groups, OIDC/IRSA provider
├── rds/        ← Multi-AZ PostgreSQL, encryption, Performance Insights
└── iam-role/   ← Reusable IAM role with IRSA and cross-account trust support
```

### Key design decisions

| Pattern | Why |
|---|---|
| One `main.tf` per environment | Eliminates workspace confusion; each environment is independently plannable |
| S3 + DynamoDB remote state | State locking prevents concurrent apply conflicts across CI runs |
| `single_nat_gateway = true` in dev | Cuts NAT cost ~66% for non-prod; prod uses per-AZ NAT for HA |
| `public_endpoint = false` in prod | EKS API only reachable inside the VPC — eliminates brute-force surface |
| IRSA over node IAM roles | Pod-level AWS identity; no credential leakage across namespaces |
| SPOT for workload node group | ~70% cost reduction; system node group stays ON_DEMAND for stability |

## Modules

### `modules/vpc`

Multi-AZ VPC with public/private subnet split, configurable NAT gateway count,
Kubernetes subnet tags for ELB controller auto-discovery, and optional VPC flow
logs to CloudWatch.

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "myapp-dev"
  vpc_cidr           = "10.10.0.0/16"
  az_count           = 2
  single_nat_gateway = true   # false in prod
  enable_flow_logs   = false  # true in prod
}
```

### `modules/eks`

EKS cluster with OIDC provider for IRSA, configurable node groups (ON_DEMAND
or SPOT), SSM agent policy on nodes for shell access without bastion, and
private-only API endpoint option.

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "myapp-dev"
  cluster_version    = "1.29"
  private_subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      labels         = { role = "general" }
    }
  }
}
```

### `modules/rds`

Multi-AZ PostgreSQL with gp3 storage, storage autoscaling, Performance Insights,
CloudWatch log export, and a custom parameter group with connection/duration
logging enabled.

### `modules/iam-role`

Reusable IAM role that supports three trust models in one module:

- **AWS service** (e.g., `ec2.amazonaws.com`)
- **IRSA** — Kubernetes pod identity via OIDC (namespace + service account scoped)
- **Cross-account** — trusted role ARNs for assume-role delegation

## CI/CD Pipeline

`.github/workflows/terraform.yml` runs on every PR and merge to `main`:

| Trigger | Jobs |
|---|---|
| Pull Request | `fmt -check`, `validate`, `tfsec` security scan, `plan` (posted as PR comment) |
| Merge to main | All checks + `apply` to dev |

GitHub Actions requires two secrets: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
(scoped to an IAM role with permissions to manage the resources in this repo).

## Remote State Setup

Before first `terraform init`, create the S3 bucket and DynamoDB table:

```bash
# Dev state bucket
aws s3api create-bucket \
  --bucket harika-terraform-state-dev \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket harika-terraform-state-dev \
  --versioning-configuration Status=Enabled

# State lock table (shared across envs)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Usage

```bash
# Init and plan dev
cd environments/dev
terraform init
export TF_VAR_db_password="<password>"
terraform plan

# Apply
terraform apply
```

## Tech Stack

- **Terraform** >= 1.7 · AWS provider ~> 5.0
- **GitHub Actions** — terraform CI/CD with tfsec security scan
- **AWS Services** — VPC, EKS 1.29, RDS PostgreSQL 15, IAM, CloudWatch
