################################ OUTPUTS ##################################

output "github_actions_role_arn" {
  description = "IMPORTANT: Add this value as AWS_ROLE_ARN in GitHub Secrets across all 3 repositories"
  value       = module.github_oidc.role_arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for all 9 platform components"
  value       = module.ecr.repository_urls
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.lb_dns_name
}


output "eks_cluster_name" {
  description = "EKS Cluster Name for kubectl access: aws eks update-kubeconfig --name <cluster_name> --region <region>"
  value       = module.eks.eks_cluster_name
}

output "rds_endpoint" {
  description = "PostgreSQL 16 Primary Endpoint"
  value       = module.rds.rds_endpoint
}

output "target_group_arns" {
  description = "Target Group ARNs for Kubernetes TargetGroupBindings"
  value       = module.alb.tg_arns
}
