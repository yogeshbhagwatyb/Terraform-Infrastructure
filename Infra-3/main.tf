# VPC creation
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc"
  }
}

variable "vpc_cidr" {
  description = "hi"
  default = "10.0.0.0/16"
}

# Internet Gateway creation
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

# Subnet creation
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_type == "public" ? var.public_subnet_cidr : var.private_subnet_cidr
  tags = {
    Name = var.subnet_type == "public" ? var.public_subnet_tag : var.private_subnet_tag
  }
}

# Route Table creation
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.subnet_type == "public" ? aws_internet_gateway.igw.id : null
  }
}

# Route Table Association
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

# EC2 Instance creation
resource "aws_instance" "ec2_instance" {
  ami           = "ami-09040d770ffe2224f"
  instance_type = var.subnet_type == "public" ? var.instance_type : var.instance_2_type
  key_name      = "TF_key"
  subnet_id     = aws_subnet.subnet.id
  count         = var.subnet_type == "public" ? 1 : 0
  tags = {
    Name = var.subnet_type == "public" ? var.instance_tag : var.instance_2_tag
  }
}
