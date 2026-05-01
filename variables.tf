variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name used as the SSM parameter path prefix"
  type        = string
}

variable "app_version" {
  description = "Application version stored in the SSM parameter"
  type        = string
  default     = "0.1.0"
}
