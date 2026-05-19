# =============================================================================
# CORE
# =============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for local runs. Leave empty in CI (uses OIDC env vars)."
  type        = string
  default     = ""
}

