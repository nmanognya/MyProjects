terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Portfolio   = "aws-eks-platform-reference"
    }
  }
}

module "networking" {
  source = "../../modules/networking"

  name                 = "portfolio-eks-dev"
  vpc_cidr             = "10.20.0.0/16"
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

  tags = {
    Owner = "platform-engineering"
  }
}
