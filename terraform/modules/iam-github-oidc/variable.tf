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

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN for ECR encryption"
}

variable "github_repositories" {
  type        = list(string)
  description = "List of GitHub repositories allowed to assume this role (format: owner/repo)"
  default = [
    "Hieuej147/ecommerce-backend",
    "Hieuej147/-E-commerce",
    "Hieuej147/dashboard-admin-ecommern"
  ]
}
