output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}

output "rds_endpoint" {
  value = aws_db_instance.orders_db.address
}
