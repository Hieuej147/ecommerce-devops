variable "project" {
  type = object({
    name = string
    env  = string
  })
  description = "Project name and environment"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
}

variable "kms_key" {
  type        = string
  description = "KMS Key ARN for ECR encryption"
}

variable "repositories" {
  type        = list(string)
  description = "List of ECR repository component names"
  default = [
    "api-gateway",
    "catalog",
    "order",
    "payment",
    "users",
    "agent-service",
    "agent-python",
    "storefront",
    "admin-dashboard"
  ]
}
