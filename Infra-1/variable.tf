variable "subnet_type" {
  description = "Type of subnet to create: 'public' or 'private'"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
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

variable "instance_type" {
  description = "Instance type for the EC2 instance in the public subnet"
  type        = string
  default     = "t2.micro"
}

variable "instance_2_type" {
  description = "Instance type for the EC2 instance in the private subnet"
  type        = string
  default     = "t2.micro"
}

variable "instance_tag" {
  description = "Tag for the EC2 instance in the public subnet"
  type        = string
  default     = "public"
}

variable "instance_2_tag" {
  description = "Tag for the EC2 instance in the private subnet"
  type        = string
  default     = "private"
}
