variable "instance_name" {
  description = "Cloud SQL instance name"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_id" {
  description = "VPC network self-link for private IP"
  type        = string
}

variable "database_version" {
  description = "Database engine version"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Cloud SQL machine tier (e.g., db-g1-small, db-custom-2-7680)"
  type        = string
  default     = "db-g1-small"
}

variable "disk_size_gb" {
  description = "Initial disk size in GB"
  type        = number
  default     = 20
}

variable "high_availability" {
  description = "Enable regional high availability (multi-zone standby)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental instance deletion"
  type        = bool
  default     = true
}

variable "backup_retention_count" {
  description = "Number of automated backups to retain"
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "Transaction log retention for point-in-time recovery"
  type        = number
  default     = 7
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
}

variable "db_user" {
  description = "Initial database user"
  type        = string
}

variable "db_password" {
  description = "Password for the initial database user"
  type        = string
  sensitive   = true
}
