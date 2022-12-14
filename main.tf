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

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
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
    Name = "${var.environment_name}-rtb-public"
  }
}

# associate public subnet 1 with public route table
resource "aws_route_table_association" "tfe_public1" {
  subnet_id      = aws_subnet.tfe_public1.id
  route_table_id = aws_default_route_table.tfe.id
}

# associate public subnet 2 with public route table
resource "aws_route_table_association" "tfe_public2" {
  subnet_id      = aws_subnet.tfe_public2.id
  route_table_id = aws_default_route_table.tfe.id
}

# create public ip
resource "aws_eip" "eip_tfe" {
  vpc = true
  tags = {
    Name = "${var.environment_name}-eip"
  }
}

# nat gateway
resource "aws_nat_gateway" "tfe_nat" {
  allocation_id = aws_eip.eip_tfe.id
  subnet_id     = aws_subnet.tfe_public1.id

  tags = {
    Name = "${var.environment_name}-nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.tfe_igw]
}

# private route table
resource "aws_route_table" "tfe_private" {
  vpc_id = aws_vpc.tfe.id

  route {
    cidr_block = local.all_ips
    nat_gateway_id = aws_nat_gateway.tfe_nat.id
  }

  tags = {
    Name = "${var.environment_name}-rtb-private"
  }
}

# associate private subnet 1 with private route table
resource "aws_route_table_association" "tfe_private1" {
  subnet_id      = aws_subnet.tfe_private1.id
  route_table_id = aws_route_table.tfe_private.id
}

# associate private subnet 2 with private route table
resource "aws_route_table_association" "tfe_private2" {
  subnet_id      = aws_subnet.tfe_private2.id
  route_table_id = aws_route_table.tfe_private.id
}

# key pair
# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# key pair in aws
resource "aws_key_pair" "tfe" {
  key_name   = "${var.environment_name}-keypair"
  public_key = tls_private_key.rsa-4096.public_key_openssh
}

# store private ssh key locally
resource "local_file" "tfesshkey" {
  content         = tls_private_key.rsa-4096.private_key_pem
  filename        = "${path.module}/tfesshkey.pem"
  file_permission = "0600"
}

# security group
resource "aws_security_group" "tfe_sg" {
  name   = "${var.environment_name}-sg"
  vpc_id = aws_vpc.tfe.id

  tags = {
    Name = "${var.environment_name}-sg"
  }
}

# sg rule ssh inbound
resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.ssh_port
  to_port     = var.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

# sg rule https inbound
resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.https_port
  to_port     = var.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

# sg rule https inbound
resource "aws_security_group_rule" "allow_replicated_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.replicated_port
  to_port     = var.replicated_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

# sg rule postgresql local vpc inbound
resource "aws_security_group_rule" "allow_postgresql_inbound_vpc" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.postgresql_port
  to_port     = var.postgresql_port
  protocol    = local.tcp_protocol
  cidr_blocks = [aws_vpc.tfe.cidr_block]
}

# sg rule all outbound
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = [local.all_ips]
}

# s3 bucket
resource "aws_s3_bucket" "tfe_files" {
  bucket = "${var.environment_name}-filesbucket"

  tags = {
    Name = "${var.environment_name}-filesbucket"
  }
}

# disable all public bucket access
resource "aws_s3_bucket_public_access_block" "tfe_files" {
  bucket = aws_s3_bucket.tfe_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# s3 bucket
resource "aws_s3_bucket" "tfe" {
  bucket = "${var.environment_name}-bucket"

  tags = {
    Name = "${var.environment_name}-bucket"
  }
}

# disable all public bucket access
resource "aws_s3_bucket_public_access_block" "tfe" {
  bucket = aws_s3_bucket.tfe.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# postgresql rds
resource "aws_db_instance" "tfe" {
  identifier          = "${var.environment_name}-postgres"
  allocated_storage   = 50
  db_name             = "tfe"
  engine              = "postgres"
  engine_version      = "14.5"
  instance_class      = "db.m5.large"
  username            = "postgres"
  password            = var.postgresql_password
  skip_final_snapshot = true

  multi_az               = false
  vpc_security_group_ids = [aws_security_group.tfe_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.tfe.name

  tags = {
    Name = "${var.environment_name}-postgres"
  }
}

# database subnet group
resource "aws_db_subnet_group" "tfe" {
  name       = "${var.environment_name}-subnetgroup"
  subnet_ids = [aws_subnet.tfe_private1.id, aws_subnet.tfe_private2.id]

  tags = {
    Name = "${var.environment_name}-subnetgroup"
  }
}