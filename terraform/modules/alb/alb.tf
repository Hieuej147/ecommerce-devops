########################### EXTERNAL APPLICATION LOAD BALANCER ###########################

resource "aws_lb" "lb" {
  name               = "${var.project.env}-${var.project.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = var.alb_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-alb"
  })
}

# HTTP Listener - Redirect 80 to 443
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener - 443 with ACM Certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.alb_dns_cert

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
      message_body = "Not Found - Request host header does not match any known service."
    }
  }
}
