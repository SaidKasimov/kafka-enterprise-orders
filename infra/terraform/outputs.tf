output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}

output "rds_endpoint" {
  value = aws_db_instance.orders_db.address
}

data "aws_secretsmanager_secret" "rds_password_secret" {
  name = "rds-master-password-for-project-x"
}

data "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id = data.aws_secretsmanager_secret.rds_password_secret.id
}
