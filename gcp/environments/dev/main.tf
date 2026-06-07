terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "harika-terraform-state-dev"
    prefix = "gcp/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  env  = "dev"
  name = "${var.project}-${local.env}"
}

# ── VPC ───────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  name       = local.name
  project_id = var.project_id
  region     = var.region

  subnets = [
    {
      name = "${local.name}-nodes"
      cidr = "10.10.0.0/20"
      secondary_ranges = [
        { range_name = "pods",     cidr = "10.11.0.0/16" },
        { range_name = "services", cidr = "10.12.0.0/20" },
      ]
    }
  ]
}

# ── GKE ───────────────────────────────────────────────────────────────────────

module "gke" {
  source = "../../modules/gke"

  cluster_name        = local.name
  project_id          = var.project_id
  region              = var.region
  network_id          = module.vpc.network_id
  subnet_id           = module.vpc.subnet_ids["${local.name}-nodes"]
  pods_range_name     = "pods"
  services_range_name = "services"
  master_cidr         = "172.16.0.16/28"
  release_channel     = "REGULAR"

  node_pools = {
    general = {
      machine_type = "e2-medium"
      disk_size_gb = 50
      node_count   = 1
      min_count    = 1
      max_count    = 3
      spot         = true
      labels       = { role = "general" }
    }
  }
}

# ── Cloud SQL ─────────────────────────────────────────────────────────────────

module "cloudsql" {
  source = "../../modules/cloudsql"

  instance_name     = local.name
  project_id        = var.project_id
  region            = var.region
  network_id        = module.vpc.network_id
  db_name           = "appdb"
  db_user           = "dbadmin"
  db_password       = var.db_password
  tier              = "db-g1-small"
  disk_size_gb      = 10
  high_availability = false
  deletion_protection = false
}
