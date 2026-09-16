terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Cluster state is isolated from the database state.
  backend "s3" {
    bucket = "auto-repair-terraform-state"
    key    = "k8s/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "auto-repair-shop"
      Environment = var.environment
      Stack       = "kubernetes"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "auto-repair-${var.environment}"
}
