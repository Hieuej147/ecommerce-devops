############################## RDS SECURITY GROUP ##############################

resource "aws_security_group" "sg_db" {
  name        = "${var.project.env}-${var.project.name}-rds-sg"
  description = "Security group for PostgreSQL RDS instance"
  vpc_id      = var.rds_vpc_id

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-rds-sg"
  })
}

resource "aws_security_group_rule" "ingress_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg_db.id
  source_security_group_id = each.value
  for_each                 = toset(var.rds_allowed_sg)
  description              = "Allow PostgreSQL access from allowed security group"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg_db.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}
