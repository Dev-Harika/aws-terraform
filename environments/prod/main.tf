terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "harika-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  env  = "prod"
  name = "${var.project}-${local.env}"

  common_tags = {
    Project     = var.project
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  vpc_cidr           = "10.20.0.0/16"
  az_count           = 3
  single_nat_gateway = false
  enable_flow_logs   = true
  tags               = local.common_tags
}

# ── EKS ───────────────────────────────────────────────────────────────────────

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.name
  cluster_version    = "1.29"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_endpoint    = false

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      labels         = { role = "system" }
    }
    workload = {
      instance_types = ["m5.xlarge", "m5.2xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      labels         = { role = "workload" }
    }
  }

  tags = local.common_tags
}

# ── RDS ───────────────────────────────────────────────────────────────────────

module "rds" {
  source = "../../modules/rds"

  identifier  = local.name
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  db_name     = "appdb"
  db_username = "dbadmin"
  db_password = var.db_password

  instance_class        = "db.r6g.large"
  allocated_storage     = 100
  max_allocated_storage = 500
  multi_az              = true
  deletion_protection   = true
  backup_retention_days = 14

  tags = local.common_tags
}

# ── External Secrets IRSA ─────────────────────────────────────────────────────

module "external_secrets_role" {
  source = "../../modules/iam-role"

  name                 = "${local.name}-external-secrets"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  irsa_namespace       = "external-secrets"
  irsa_service_account = "external-secrets"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]

  tags = local.common_tags
}
