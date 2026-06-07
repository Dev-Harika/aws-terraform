variable "name" {
  description = "Prefix for all resource names"
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

variable "subnets" {
  description = "List of subnet definitions"
  type = list(object({
    name = string
    cidr = string
    secondary_ranges = optional(list(object({
      range_name = string
      cidr       = string
    })), [])
  }))
}
