########################### TARGET GROUPS #####################################

#================== Storefront ==================#
resource "aws_lb_target_group" "storefront" {
  name                 = "${var.project.env}-${var.project.name}-store"
  port                 = 3001
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.alb_vpc_id
  deregistration_delay = 30

  health_check {
    interval            = 20
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name      = "${var.project.env}-${var.project.name}-store"
    Component = "storefront"
  })
}

#================== Admin Dashboard ==================#
resource "aws_lb_target_group" "admin" {
  name                 = "${var.project.env}-${var.project.name}-admin"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.alb_vpc_id
  deregistration_delay = 30

  health_check {
    interval            = 20
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name      = "${var.project.env}-${var.project.name}-admin"
    Component = "admin-dashboard"
  })
}

#================== API Gateway ==================#
resource "aws_lb_target_group" "api_gateway" {
  name                 = "${var.project.env}-${var.project.name}-api"
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.alb_vpc_id
  deregistration_delay = 30

  health_check {
    interval            = 20
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name      = "${var.project.env}-${var.project.name}-api"
    Component = "api-gateway"
  })
}

#================== ArgoCD ==================#
resource "aws_lb_target_group" "argocd" {
  name                 = "${var.project.env}-${var.project.name}-argocd"
  port                 = 443
  protocol             = "HTTPS"
  target_type          = "ip"
  vpc_id               = var.alb_vpc_id
  deregistration_delay = 30

  health_check {
    interval            = 20
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name      = "${var.project.env}-${var.project.name}-argocd"
    Component = "argocd"
  })
}
