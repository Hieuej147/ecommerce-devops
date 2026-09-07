################################ OUTPUTS ################################

output "rds_endpoint" {
  description = "PostgreSQL primary endpoint host:port"
  value       = aws_db_instance.db.endpoint
}

output "rds_address" {
  description = "PostgreSQL primary host address"
  value       = aws_db_instance.db.address
}

output "rds_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.db.port
}

output "rds_arn" {
  description = "ARN of the PostgreSQL RDS instance"
  value       = aws_db_instance.db.arn
}

output "rds_credentials" {
  description = "RDS credentials and connection strings"
  sensitive   = true
  value = {
    DATABASE_USERNAME = aws_db_instance.db.username
    DATABASE_PASSWORD = random_password.rds.result
    DATABASE_HOST     = aws_db_instance.db.address
    DATABASE_PORT     = tostring(aws_db_instance.db.port)
    DATABASE_NAME     = aws_db_instance.db.db_name
    DATABASE_URL      = "postgresql://${aws_db_instance.db.username}:${random_password.rds.result}@${aws_db_instance.db.address}:${aws_db_instance.db.port}/${aws_db_instance.db.db_name}?schema=public"
  }
}
