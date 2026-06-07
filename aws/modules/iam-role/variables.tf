variable "name" {
  description = "IAM role name"
  type        = string
}

variable "trusted_services" {
  description = "AWS services that can assume this role (e.g., ec2.amazonaws.com)"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "IAM role ARNs that can assume this role (cross-account)"
  type        = list(string)
  default     = []
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA trust"
  type        = string
  default     = null
}

variable "irsa_namespace" {
  description = "Kubernetes namespace for IRSA trust (required if oidc_provider_arn is set)"
  type        = string
  default     = null
}

variable "irsa_service_account" {
  description = "Kubernetes service account name for IRSA trust"
  type        = string
  default     = "*"
}

variable "managed_policy_arns" {
  description = "AWS managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "JSON string for an inline policy (use jsonencode() in the caller)"
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600–43200)"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
