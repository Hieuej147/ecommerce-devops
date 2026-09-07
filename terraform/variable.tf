################################ VARIABLES ##################################

variable "project" {
  type = object({
    name       = string
    env        = string
    region     = string
    account_id = string
    domain     = string
    admin_user = string
  })
  description = "Project core configuration"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all AWS resources"
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Project     = "ecommerce"
  }
}

variable "helm_repo" {
  type        = string
  description = "GitOps manifest repository URL"
  default     = "https://github.com/Hieuej147/ecommerce-devops.git"
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "Allowed CIDR blocks for administrative access"
  default     = ["0.0.0.0/0"]
}

variable "github_repositories" {
  type        = list(string)
  description = "GitHub repositories allowed to push images via AWS OIDC"
  default = [
    "Hieuej147/ecommerce-backend",
    "Hieuej147/-E-commerce",
    "Hieuej147/dashboard-admin-ecommern"
  ]
}
