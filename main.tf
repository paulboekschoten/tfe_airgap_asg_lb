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

# public subnet
resource "aws_subnet" "tfe_public1" {
  vpc_id     = aws_vpc.tfe.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.environment_name}-subnet-public1"
  }
}

resource "aws_subnet" "tfe_public2" {
  vpc_id     = aws_vpc.tfe.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.environment_name}-subnet-public2"
  }
}

# private subnet
resource "aws_subnet" "tfe_private1" {
  vpc_id            = aws_vpc.tfe.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.environment_name}-subnet-private1"
  }
}

# private subnet
resource "aws_subnet" "tfe_private2" {
  vpc_id            = aws_vpc.tfe.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 3)
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.environment_name}-subnet-private2"
  }
}

# internet gateway
resource "aws_internet_gateway" "tfe_igw" {
  vpc_id = aws_vpc.tfe.id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}

# add igw to default vpc route table
resource "aws_default_route_table" "tfe" {
  default_route_table_id = aws_vpc.tfe.default_route_table_id

  route {
    cidr_block = local.all_ips
    gateway_id = aws_internet_gateway.tfe_igw.id
  }

  tags = {
    Name = "${var.environment_name}-rtb"
  }
}

# create public ip
resource "aws_eip" "eip_tfe" {
  vpc = true
  tags = {
    Name = "${var.environment_name}-eip"
  }
}