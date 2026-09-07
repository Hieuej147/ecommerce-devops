########################### ALB SECURITY GROUP ###########################

resource "aws_security_group" "sg_lb" {
  name        = "${var.project.env}-${var.project.name}-alb-sg"
  description = "Security group for external Application Load Balancer"
  vpc_id      = var.alb_vpc_id

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-alb-sg"
  })
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_lb.id
  description       = "Allow HTTP from internet for redirect"
}

resource "aws_security_group_rule" "ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_lb.id
  description       = "Allow HTTPS from internet"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_lb.id
  description       = "Allow all outbound traffic to backend Pods"
}
