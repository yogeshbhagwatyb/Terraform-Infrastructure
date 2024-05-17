[5:44 PM] Bhagwat, Yogesh
# Variables
variable "aws_region" {
  description = "AWS region where infrastructure will be created"
  type        = string
}
 
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
 
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}
 
variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}
 
variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
}
 
variable "subnet_type" {
  description = "Type of subnet to create: 'public' or 'private'"
  type        = string
}
 
variable "public_subnet_tag" {
  description = "Tag for the public subnet"
  type        = string
  default     = "public"
}
 
variable "private_subnet_tag" {
  description = "Tag for the private subnet"
  type        = string
  default     = "private"
}
 
variable "create_ec2_instance" {
  description = "Whether to create an EC2 instance in the subnet"
  type        = string
  default     = "yes"
}
 
variable "use_linux" {
  description = "Whether to use Amazon Linux 2 (true) or Windows (false)"
  type        = bool
}
 
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing Terraform state"
  type        = string
}
 
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}
 
# Local Values
locals {
  s3_bucket_name       = var.s3_bucket_name
  dynamodb_table_name  = var.dynamodb_table_name
  aws_region           = var.aws_region
  timestamp            = regex_replace(timestamp(), "[- TZ:]", "")
}
 
# Data Sources
data "aws_ami" "amazon_linux_2" {
  most_recent = true
 
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
 
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
 
  owners = ["amazon"]
}
 
data "aws_ami" "windows" {
  most_recent = true
 
  filter {
    name   = "name"
    values = ["Windows_Server-*"]
  }
 
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
 
  owners = ["amazon"]
}
 
# User Data Script
data "template_file" "userdata" {
  template = <<EOF
#!/bin/bash
sudo yum install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
EOF
}
 
# Provider
provider "aws" {
  region  = local.aws_region
  profile = "default"
}
 
# IAM Role and Policy Attachment for SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
 
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
 
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2_ssm_profile"
  role = aws_iam_role.ec2_ssm_role.name
}
 
# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc"
  }
}
 
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw"
  }
}
 
# Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr
  tags = {
    Name = var.public_subnet_tag
  }
}
 
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr
  tags = {
    Name = var.private_subnet_tag
  }
}
 
# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_rt"
  }
}
 
# Route Table Association for Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
 
# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  count = var.subnet_type == "private" ? 1 : 0
}
 
# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  count         = var.subnet_type == "private" ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "nat_gw"
  }
}
 
# Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
 
  tags = {
    Name = "private_rt"
  }
 
  lifecycle {
    ignore_changes = [route]
  }
}
 
resource "aws_route" "private_route" {
  count = var.subnet_type == "private" ? 1 : 0
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw[0].id
}
 
# Security Group
resource "aws_security_group" "sg" {
  name        = "security_group"
  description = "allow all inbound traffic"
  vpc_id      = aws_vpc.vpc.id
 
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  tags = {
    Name = "tcw_security_group"
  }
}
 
# Key Pair
resource "aws_key_pair" "TF_key" {
  key_name   = "TF_key"
  public_key = tls_private_key.rsa.public_key_openssh
}
 
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
 
resource "local_file" "TF-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey"
}
 
# EC2 Instance in Public or Private Subnet
resource "aws_instance" "ec2_instance" {
  ami                    = var.use_linux ? data.aws_ami.amazon_linux_2.id : data.aws_ami.windows.id
  instance_type          = var.instance_type
  key_name               = "TF_key"
  subnet_id              = var.subnet_type == "public" ? aws_subnet.public_subnet.id : aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = var.use_linux ? data.template_file.userdata.rendered : null
  count                  = var.create_ec2_instance == "yes" ? 1 : 0
  iam_instance_profile   = var.subnet_type == "private" ? aws_iam_instance_profile.ec2_ssm_profile.name : null
 
  tags = {
    Name = "EC2_Instance"
  }
}
 
# S3 Bucket for Remote State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.s3_bucket_name
 
  # versioning {
  #   enabled = true
  # }
 
  tags = {
    Name = "terraform_state"
  }
}
 
 
 
 
# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags = {
    Name = "terraform_locks"
  }
}
 
##########################Delet
# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
 
  tags = {
    Name = "my_vpc"
  }
}
 
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.my_vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "public_sg"
  }
}
 
resource "aws_security_group" "public_sg1" {
  vpc_id = aws_vpc.my_vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "public_sg"
  }
}
 
resource "aws_security_group" "public_sg2" {
  vpc_id = aws_vpc.my_vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "public_sg"
  }
}
 
resource "aws_security_group" "public_sg3" {
  vpc_id = aws_vpc.my_vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "public_sg"
  }
}
[5:44 PM] Bhagwat, Yogesh
 
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
 
# Generate a unique identifier (UUID)
#$uniqueId = [guid]::NewGuid().ToString()
 
$backendConfig = @"
terraform {
  backend "s3" {
    bucket         = "izn-bucket-2-2-2"
    key            = "terraform/state-$($timestamp)-$uniqueId"
    region         = "eu-west-1"
    dynamodb_table = "izn-table-2-2-2"
    encrypt        = true
  }
}
"@
 
$backendFilePath = "backend.tf"      
$backendConfig | Out-File -FilePath $backendFilePath -Encoding ascii
 
 
Write-Output "Configuring Terraform backend..."
terraform init -backend-config=$backendFilePath -force-copy
 
 
if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform initialization failed. Exiting script."
    Exit $LASTEXITCODE
}
 
Write-Output "Running Terraform plan..."
terraform plan $args
 
if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform plan failed. Exiting script."
    Exit $LASTEXITCODE
}
 
Write-Output "Applying Terraform configuration..."
terraform apply -auto-approve $args
 
if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform apply failed. Exiting script."
    Exit $LASTEXITCODE
}
 
 
Write-Output "Cleaning up temporary files..."
Remove-Item -Path $backendFilePath
 
Write-Output "Terraform operations completed successfully."
 
[5:44 PM] Bhagwat, Yogesh
#variable "ec2_metadata_service_endpoint" {}
 
terraform {
  backend "s3" {
    bucket         = "izn-bucket-2-2-2"
    key            = "terraform/state-${TIMESTAMP}"
    region         = "eu-west-1"
    dynamodb_table = "izn-table-2-2-2"
    #endpoint = "http://${var.ec2_metadata_service_endpoint}/"
    encrypt        = true
  }
}
 
# # terraform {
# #   backend "s3" {
# #     config_file = "backend.tfvars"
# #   }
# # }
 
 
# variable "ec2_metadata_service_endpoint" {}
 
# terraform {
#   backend "s3" {
#     #bucket = "mybucket"
#     #key    = "path/to/my/key"
#     #region = "us-east-1"
 
#     #endpoint = "http://${var.ec2_metadata_service_endpoint}/"
#   }
# }
 
# Backend Configuration
terraform {
  backend "s3" {
    bucket         = "izn-bucket-2-2-2"
    key            = "terraform/state/${local.timestamp}/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "izn-table-2-2-2"
  }
}
