# Multi-Cloud Infrastructure — Terraform

Production-grade AWS and GCP infrastructure as code using reusable Terraform modules.
Demonstrates 6+ years of Terraform/DevOps experience with real-world platform engineering
patterns: multi-cloud multi-environment separation, remote state locking, pod-level cloud
identity (IRSA / Workload Identity), and automated CI/CD via GitHub Actions.

![CI](https://github.com/Dev-Harika/aws-terraform/actions/workflows/terraform.yml/badge.svg)

## Repository Structure

```
aws/
├── modules/
│   ├── vpc/        ← Multi-AZ VPC, public/private subnets, NAT gateway, flow logs
│   ├── eks/        ← EKS cluster, managed node groups, OIDC/IRSA provider
│   ├── rds/        ← Multi-AZ PostgreSQL, encryption, Performance Insights
│   └── iam-role/   ← Reusable role: AWS service / IRSA / cross-account trust
└── environments/
    ├── dev/        ← 2-AZ, spot nodes, single NAT, no deletion protection
    └── prod/       ← 3-AZ, on-demand+spot, per-AZ NAT, Multi-AZ RDS, flow logs

gcp/
├── modules/
│   ├── vpc/        ← VPC, private subnets with secondary ranges, Cloud NAT
│   ├── gke/        ← GKE cluster, Workload Identity, configurable node pools
│   └── cloudsql/   ← Cloud SQL PostgreSQL, private IP, HA, Point-in-Time Recovery
└── environments/
    ├── dev/        ← e2-medium spot nodes, single-zone SQL, cost-optimized
    └── prod/       ← e2-standard on-demand system + spot workload, regional HA SQL
```

## AWS

### Key design decisions

| Pattern | Why |
|---|---|
| One `main.tf` per environment | Eliminates workspace confusion; each environment is independently plannable |
| S3 + DynamoDB remote state | State locking prevents concurrent apply conflicts across CI runs |
| `single_nat_gateway = true` in dev | Cuts NAT cost ~66%; prod uses per-AZ NAT for HA |
| `public_endpoint = false` in prod | EKS API only reachable inside the VPC |
| IRSA over node IAM roles | Pod-level AWS identity; no credential leakage across namespaces |
| SPOT for workload node group | ~70% cost reduction; system nodes stay ON_DEMAND |

### Modules

**`aws/modules/vpc`** — Multi-AZ VPC with public/private subnet split, configurable NAT
gateway count, Kubernetes subnet tags for ELB controller auto-discovery, and optional VPC
flow logs to CloudWatch.

**`aws/modules/eks`** — EKS 1.29 cluster with OIDC provider for IRSA, configurable node
groups (ON_DEMAND or SPOT), SSM agent policy on nodes, and private-only API endpoint option.

**`aws/modules/rds`** — Multi-AZ PostgreSQL 15 with gp3 storage autoscaling, Performance
Insights, CloudWatch log export, and connection/duration logging.

**`aws/modules/iam-role`** — Reusable IAM role supporting AWS service, IRSA
(namespace-scoped), and cross-account trust — all in one module.

### Usage

```bash
cd aws/environments/dev
terraform init
export TF_VAR_db_password="<password>"
terraform plan && terraform apply
```

## GCP

### Key design decisions

| Pattern | Why |
|---|---|
| Private IP only for Cloud SQL | No public endpoint; accessed via Cloud SQL Proxy or VPC peering |
| Workload Identity on GKE | GKE equivalent of IRSA — pods authenticate as GCP service accounts |
| Secondary IP ranges | Separate CIDR pools for pods and services required by VPC-native GKE |
| GCS remote state | GCS bucket with versioning as the Terraform backend for GCP environments |
| `spot = true` for dev workloads | ~70% cheaper than on-demand for interruptible dev workloads |

### Modules

**`gcp/modules/vpc`** — VPC network with private subnets, secondary IP ranges for
GKE pods/services, Cloud Router, and Cloud NAT for outbound internet access.

**`gcp/modules/gke`** — GKE cluster with Workload Identity enabled, private nodes,
configurable node pools (spot or on-demand), and auto-repair/auto-upgrade.

**`gcp/modules/cloudsql`** — Cloud SQL PostgreSQL 15 with private IP, regional HA,
Point-in-Time Recovery, Query Insights, and SSL enforcement.

### Usage

```bash
cd gcp/environments/dev
terraform init
export TF_VAR_project_id="my-gcp-project"
export TF_VAR_db_password="<password>"
terraform plan && terraform apply
```

## CI/CD Pipeline

`.github/workflows/terraform.yml` runs on every PR and merge to `main`:

| Trigger | Jobs |
|---|---|
| Pull Request | `fmt -check`, `validate`, `tfsec` security scan, plan posted as PR comment |
| Merge to main | All checks + `apply` to dev |

Required GitHub secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

## Tech Stack

- **Terraform** >= 1.7 · AWS provider ~> 5.0 · Google provider ~> 5.0
- **GitHub Actions** — CI/CD with tfsec security scanning
- **AWS** — VPC, EKS 1.29, RDS PostgreSQL 15, IAM, CloudWatch
- **GCP** — VPC, GKE, Cloud SQL PostgreSQL 15, Cloud NAT, Workload Identity
