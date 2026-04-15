###############################################################################
# Variables for Healthcare AI Platform
###############################################################################

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "healthcare-ai"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Primary Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

variable "openai_location" {
  description = "Azure region for OpenAI service (limited availability)"
  type        = string
  default     = "eastus"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps-Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Healthcare-Innovation"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28"
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}
