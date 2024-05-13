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
  #default     = "10.0.0.32/27"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  #default     = "10.0.0.0/27"
}

# Prompt for EC2 instance type
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
