############################## RDS POSTGRESQL VARIABLES ##############################

variable "project" {
  type        = map(string)
  description = "Project configuration (name, env, region)"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
}

variable "rds_vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "rds_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the RDS subnet group"
}

variable "rds_allowed_sg" {
  type        = list(string)
  description = "List of allowed security group IDs to RDS instance (e.g. EKS node group SG, Bastion SG)"
}

variable "kms_key" {
  type        = string
  description = "KMS key ARN for RDS at-rest encryption"
}

variable "instance_class" {
  type        = string
  description = "RDS Instance Class"
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum storage auto-scaling limit in GB"
  default     = 50
}
