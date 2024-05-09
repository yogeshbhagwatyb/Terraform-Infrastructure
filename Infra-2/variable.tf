variable "region-type" {
  description = "We can select regions as per input"
  default     = "us-east-2"
}

variable "vpc-cidr" {
  description = "This is cidr will use for to create vpc"
  default     = "10.0.0.0/27"
}

variable "vpc-tag" {
  description = "This is VPC tags"
  default     = "EzDevops-VPC"
}

variable "public-subnet-cidr" {
  description = "This is cidr will use to create Public Subnet"
  default     = "10.0.0.0/28" #IP addresses ranging from 10.0.0.1 to 10.0.0.14
}

variable "public-subnet-tag" {
  description = "This will use to tag Public Subnet"
  default     = "EzDevops-Public-Subnet"
}

variable "igw-tag" {
  description = "This will use to tag IGW"
  default     = "Internet-Gateway"
}

variable "public-route-table-tag" {
  description = "This will use to tag Public-Route-Table"
  default     = "EzDevops-Public-Route-Table"
}

variable "private-subnet-cidr" {
  description = "This is cidr will use to create Public Subnet"
  default     = "10.0.0.16/28" #IP addresses ranging from 10.0.0.17 to 10.0.0.30
}

variable "private-subnet-tag" {
  description = "This will use to tag Public Subnet"
  default     = "EzDevops-Public-Subnet"
}

variable "private-route-table-tag" {
  description = "This will use to tag Private-Route-Table"
  default     = "EzDevops-Private-Route-Table"
}

variable "instance-type" {
  description = "This use to select instance type"
  default     = "t2.micro"
}

variable "instance-tag" {
  description = "This use to tag instance"
  default     = "EzDevops-Public-Instance"
}


variable "instance-2-type" {
  description = "This use to select instance type"
  default     = "t2.micro"
}

variable "instance-2-tag" {
  description = "This use to tag instance"
  default     = "EzDevops-Private-Instance"
}

variable "subnet-type" {
  description = "Select the type of subnet to create (public or private)"
  type        = string
}
