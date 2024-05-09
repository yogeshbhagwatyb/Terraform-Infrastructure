###VPC###
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc-tag
  }
}

###Public Subnet###
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public-subnet-cidr
  #map_public_ip_on_launch = true
  map_public_ip_on_launch = var.subnet-type == "public" ? true : false
  tags = {
    Name = var.public-subnet-tag
  }
}

# ###Internet Gateway###
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.vpc.id

#   tags = {
#     Name = var.igw-tag
#   }
# }

# Internet Gateway creation
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw-tag
  }
}

# Public Route Table creation (conditionally)
resource "aws_route_table" "public_route_table" {
  count  = var.subnet-type == "public" ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}


# ###Public-Route-Table###
# resource "aws_route_table" "public_route_table" {
#   vpc_id = aws_vpc.vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
# }

resource "aws_route_table_association" "public_subnet_association" {
  count           = var.subnet-type == "public" ? 1 : 0
  subnet_id       = aws_subnet.public_subnet[count.index].id
  route_table_id  = aws_route_table.public_route_table[count.index].id
}

# ###Public Route Table Association###
# resource "aws_route_table_association" "public_subnet_association" {
#   subnet_id      = aws_subnet.public_subnet.id
#   route_table_id = aws_route_table.public_route_table.id
# }

# Private Route Table creation
resource "aws_route_table" "private_route_table" {
  count  = var.subnet-type == "private" ? 1 : 0 # Create only if it's a private subnet
  vpc_id = aws_vpc.vpc.id
}

# Private Route Table Association
resource "aws_route_table_association" "private_subnet_association" {
  count          = var.subnet-type == "private" ? 1 : 0 # Associate only if it's a private subnet
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# ###Private Subnet###
# resource "aws_subnet" "private_subnet" {
#   vpc_id                  = aws_vpc.vpc.id
#   cidr_block              = var.private-subnet-cidr
#   map_public_ip_on_launch = true

#   tags = {
#     Name = var.private-subnet-tag
#   }
# }

# ###Private Route Table###
# resource "aws_route_table" "private_route_table" {
#   vpc_id = aws_vpc.vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
# }

# ###Private Route Table Association###
# resource "aws_route_table_association" "private_subnet_association" {
#   subnet_id      = aws_subnet.private_subnet.id
#   route_table_id = aws_route_table.private_route_table.id
# }

###AWS Key Pair###
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

###Security Group###
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "MySecurityGroup"
  }
}

# ###Public EC2 Instance###
# resource "aws_instance" "my_ec2_instance" {
#   ami           = "ami-09040d770ffe2224f"
#   instance_type = var.instance-type
#   key_name      = "TF_key"

#   subnet_id       = aws_subnet.public_subnet.id
#   #security_groups = [aws_security_group.my_security_group.name]
#   tags = {
#     Name = var.instance-tag
#   }
# }

# ###Private EC2 Instance###
# resource "aws_instance" "my_ec2_instance2" {
#   ami           = "ami-09040d770ffe2224f"
#   instance_type = var.instance-2-type
#   key_name      = "TF_key"

#   subnet_id       = aws_subnet.private_subnet.id
#   #security_groups = [aws_security_group.my_security_group.name]
#   tags = {
#     Name = var.instance-2-tag
#   }
# }

# Public EC2 Instance creation (conditionally)
resource "aws_instance" "my_ec2_instance" {
  count = var.subnet-type == "public" ? 1 : 0 # Create only if it's a public subnet
  ami           = "ami-09040d770ffe2224f"   # Replace with actual AMI IDs
  instance_type = var.instance-type
  key_name      = "TF_key"

  subnet_id = aws_subnet.subnet.id
  #security_groups = [aws_security_group.my_security_group.name]
  tags = {
    Name = var.instance-tag
  }
}

# Private EC2 Instance creation
resource "aws_instance" "my_ec2_instance2" {
  count = var.subnet-type == "private" ? 1 : 0 # Create only if it's a private subnet
  ami           = "ami-09040d770ffe2224f"
  instance_type = var.instance-2-type
  key_name      = "TF_key"

  subnet_id = aws_subnet.subnet.id
  #security_groups = [aws_security_group.my_security_group.name]
  tags = {
    Name = var.instance-2-tag
  }
}
