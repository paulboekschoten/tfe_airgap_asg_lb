terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.41.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.11.1"
    }
  }

  required_version = "1.3.5"
}

provider "aws" {
  region = var.region
}

# vpc
resource "aws_vpc" "tfe" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.environment_name}-vpc"
  }
}