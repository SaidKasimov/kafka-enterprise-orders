terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # For now: local state. Later you can move to S3 + DynamoDB.
}

provider "aws" {
  region = var.aws_region
}
