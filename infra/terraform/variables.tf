variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Base name for resources"
  type        = string
  default     = "kafka-enterprise-orders"
}

variable "container_image_producer" {
  description = "Docker image for order producer"
  type        = string
}

variable "container_image_fraud" {
  description = "Docker image for fraud service"
  type        = string
}

variable "container_image_payment" {
  description = "Docker image for payment service"
  type        = string
}

variable "container_image_analytics" {
  description = "Docker image for analytics service"
  type        = string
}

variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud bootstrap servers"
  type        = string
}

variable "confluent_api_key" {
  description = "Confluent Cloud API key"
  type        = string
  sensitive   = true
}

variable "confluent_api_secret" {
  description = "Confluent Cloud API secret"
  type        = string
  sensitive   = true
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "orders_user"
}
