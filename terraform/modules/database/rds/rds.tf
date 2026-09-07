##################################### RDS POSTGRESQL #####################################

resource "random_password" "rds" {
  length           = 24
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#================ Parameter Group =================#
resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "${var.project.env}-${var.project.name}-pg16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  parameter {
    name         = "max_connections"
    value        = "200"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-pg16"
  })
}

#================ Subnet Group =================#
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project.env}-${var.project.name}-rds-subnets"
  subnet_ids = var.rds_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-rds-subnets"
  })
}

#================ RDS Instance =================#
resource "aws_db_instance" "db" {
  identifier            = "${var.project.env}-${var.project.name}-postgres"
  multi_az              = false
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  storage_type       = "gp3"
  iops               = null
  storage_throughput = null

  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = var.instance_class
  db_name                = replace("${var.project.name}", "-", "_")
  username               = "postgres"
  password               = random_password.rds.result
  port                   = 5432
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_db.id]

  storage_encrypted = true
  kms_key_id        = var.kms_key

  performance_insights_enabled = false
  publicly_accessible          = false
  skip_final_snapshot          = true
  deletion_protection          = false

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true

  backup_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-postgres"
  })
}
