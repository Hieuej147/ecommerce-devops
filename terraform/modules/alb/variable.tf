######################## ALB VARIABLES ########################

variable "project" {
  type = object({
    name   = string
    env    = string
    domain = string
  })
  description = "Project configuration"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
}

variable "alb_vpc_id" {
  type        = string
  description = "VPC ID for the ALB"
}

variable "alb_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}


variable "allowed_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs for administrative tools"
  default     = ["0.0.0.0/0"]
}
