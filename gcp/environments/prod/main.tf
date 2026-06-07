terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "harika-terraform-state-prod"
    prefix = "gcp/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  env  = "prod"
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
      cidr = "10.20.0.0/20"
      secondary_ranges = [
        { range_name = "pods",     cidr = "10.21.0.0/16" },
        { range_name = "services", cidr = "10.22.0.0/20" },
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
  master_cidr         = "172.16.0.32/28"
  release_channel     = "STABLE"

  node_pools = {
    system = {
      machine_type = "e2-standard-2"
      disk_size_gb = 100
      node_count   = 2
      min_count    = 2
      max_count    = 4
      spot         = false
      labels       = { role = "system" }
    }
    workload = {
      machine_type = "e2-standard-4"
      disk_size_gb = 100
      node_count   = 2
      min_count    = 2
      max_count    = 10
      spot         = true
      labels       = { role = "workload" }
    }
  }
}

# ── Cloud SQL ─────────────────────────────────────────────────────────────────

module "cloudsql" {
  source = "../../modules/cloudsql"

  instance_name       = local.name
  project_id          = var.project_id
  region              = var.region
  network_id          = module.vpc.network_id
  db_name             = "appdb"
  db_user             = "dbadmin"
  db_password         = var.db_password
  tier                = "db-custom-2-7680"
  disk_size_gb        = 100
  high_availability   = true
  deletion_protection = true
}
