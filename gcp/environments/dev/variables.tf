variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "project" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "harika-infra"
}

variable "db_password" {
  description = "Cloud SQL master password"
  type        = string
  sensitive   = true
}
