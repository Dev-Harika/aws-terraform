variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used as a resource name prefix"
  type        = string
  default     = "harika-infra"
}

variable "db_password" {
  description = "RDS master password — supply via TF_VAR_db_password or AWS Secrets Manager"
  type        = string
  sensitive   = true
}
