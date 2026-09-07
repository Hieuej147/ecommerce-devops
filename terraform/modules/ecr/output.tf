output "repository_urls" {
  value = {
    for k, v in aws_ecr_repository.ecr : k => v.repository_url
  }
  description = "Map of component names to ECR repository URLs"
}

output "repository_arns" {
  value = {
    for k, v in aws_ecr_repository.ecr : k => v.arn
  }
  description = "Map of component names to ECR repository ARNs"
}
