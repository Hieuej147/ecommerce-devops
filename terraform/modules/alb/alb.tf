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

# HTTP Listener - Port 80 (Routed from Cloudflare Edge Proxy with Flexible SSL)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
      message_body = "Not Found - Request host header does not match any known service."
    }
  }
}
