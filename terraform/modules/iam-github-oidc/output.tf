output "role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "IAM Role ARN to configure as AWS_ROLE_ARN in GitHub repository Secrets"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "GitHub OIDC Provider ARN"
}
