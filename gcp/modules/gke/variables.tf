variable "cluster_name" {
  description = "GKE cluster name"
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
  description = "VPC network self-link"
  type        = string
}

variable "subnet_id" {
  description = "Subnet self-link for the cluster"
  type        = string
}

variable "pods_range_name" {
  description = "Secondary IP range name for pods"
  type        = string
}

variable "services_range_name" {
  description = "Secondary IP range name for services"
  type        = string
}

variable "master_cidr" {
  description = "CIDR block for the GKE control plane (/28)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_cidrs" {
  description = "CIDRs allowed to reach the GKE API"
  type = list(object({
    cidr = string
    name = string
  }))
  default = []
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    machine_type = string
    disk_size_gb = number
    node_count   = number
    min_count    = number
    max_count    = number
    spot         = bool
    labels       = map(string)
  }))
  default = {}
}
