############################### ALB LISTENER RULES ###############################

# Rule 1: Storefront (store.yourdomain.com and apex yourdomain.com)
resource "aws_lb_listener_rule" "https_storefront" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.storefront.arn
  }

  condition {
    host_header {
      values = [
        "store.${var.project.domain}",
        var.project.domain
      ]
    }
  }
}

# Rule 2: Admin Dashboard (admin.yourdomain.com)
# Note: Traffic reaching ALB here has already passed through Cloudflare Zero Trust OTP at Edge
resource "aws_lb_listener_rule" "https_admin" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }

  condition {
    host_header {
      values = [
        "admin.${var.project.domain}"
      ]
    }
  }
}

# Rule 3: API Gateway (api.yourdomain.com)
resource "aws_lb_listener_rule" "https_api_gateway" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }

  condition {
    host_header {
      values = [
        "api.${var.project.domain}"
      ]
    }
  }
}

# Rule 4: ArgoCD (argocd.yourdomain.com)
resource "aws_lb_listener_rule" "https_argocd" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.argocd.arn
  }

  condition {
    host_header {
      values = [
        "argocd.${var.project.domain}"
      ]
    }
  }

  condition {
    source_ip {
      values = var.allowed_cidrs
    }
  }
}
