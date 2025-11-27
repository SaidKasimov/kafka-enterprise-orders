####################################
# Use existing default VPC
####################################
data "aws_vpc" "main" {
  # Берём дефолтную VPC в регионе var.aws_region
  default = true
}

####################################
# Get subnets from this VPC
####################################
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Возьмём первые две сабсети из списка (обычно это public-subnets в default VPC)
locals {
  public_subnet_ids = slice(data.aws_subnets.public.ids, 0, 2)
}

####################################
# Security Group for ECS tasks
####################################
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow HTTP egress for ECS tasks"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

