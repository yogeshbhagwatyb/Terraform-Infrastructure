 terraform plan -var="aws_region=us-west-2" -var="instance_type=t2.micro" -var="subnet_type=public" -var="use_linux=true" -var="public_subnet_cidr=10.0.0.32/27" -var="private_subnet_cidr=10.0.0.0/27"

 # Prompt for AWS region
provider "aws" {
  region  = var.aws_region
  profile = "default"
}

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
  ami           = var.use_linux ? data.aws_ami.amazon_linux_2.id : data.aws_ami.windows.id
  instance_type = var.instance_type
  #key_name      = "TF_key"
  subnet_id     = aws_subnet.subnet.id
  count         = var.create_ec2_instance == "yes" ? 1 : 0
  associate_public_ip_address = true  #
  tags = {
    Name = "EC2_Instance"
  }
}

 #terraform plan -var="aws_region=us-west-2" -var="instance_type=t2.micro" -var="subnet_type=public" -var="use_linux=true" -var="public_subnet_cidr=10.0.0.32/27" -var="private_subnet_cidr=10.0.0.0/27"




