################################ OUTPUTS ################################

output "lb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.lb.id
}

output "lb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.lb.arn
}

output "lb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.lb.dns_name
}

output "lb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.lb.zone_id
}

output "lb_sg_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = aws_security_group.sg_lb.id
}

output "tg_arns" {
  description = "Map of target group ARNs"
  value = {
    storefront  = aws_lb_target_group.storefront.arn
    admin       = aws_lb_target_group.admin.arn
    api_gateway = aws_lb_target_group.api_gateway.arn
    argocd      = aws_lb_target_group.argocd.arn
  }
}
