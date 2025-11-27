####################################
# ECS cluster
####################################
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

####################################
# IAM ROLES: используем существующие
####################################

# Вместо resource "aws_iam_role" – берём уже созданную роль по имени.
# Роль должна уже существовать в AWS IAM:
#   name = "<project_name>-ecs-task-execution"
data "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution"
}

# Аналогично для task role
data "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
}

# Если хочешь, можно оставить attachment (он idempotent),
# но привязываем политику к роли, которую нашли через data.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = data.aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

####################################
# Task definition (Fargate)
####################################
resource "aws_ecs_task_definition" "order_producer" {
  family                   = "${var.project_name}-producer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  # ВАЖНО: тут теперь ссылки на data.*, а не на resource aws_iam_role.*
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "order-producer"
      image     = var.container_image_producer
      essential = true
      environment = [
        {
          name  = "KAFKA_BOOTSTRAP"
          value = var.confluent_bootstrap_servers
        },
        {
          name  = "CONFLUENT_API_KEY"
          value = var.confluent_api_key
        },
        {
          name  = "CONFLUENT_API_SECRET"
          value = var.confluent_api_secret
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          # Просто строка-имя, без отдельного ресурса log_group.
          awslogs-group         = "/ecs/${var.project_name}-producer"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

####################################
# CloudWatch Log Group
####################################
# РАНЬШЕ было так:
#
# resource "aws_cloudwatch_log_group" "producer" {
#   name              = "/ecs/${var.project_name}-producer"
#   retention_in_days = 7
# }
#
# Эта строка даёт конфликт "ResourceAlreadyExistsException",
# потому что группа логов уже есть.
#
# ПРОСТО УДАЛЯЕМ этот ресурс.
# ECS сам будет использовать существующую группу логов
# (или ты можешь создать её руками один раз).

####################################
# ECS Service
####################################
resource "aws_ecs_service" "order_producer" {
  name            = "${var.project_name}-producer-svc"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.order_producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
