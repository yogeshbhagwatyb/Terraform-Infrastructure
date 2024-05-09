resource "aws_vpc" "myVPC" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = {
    "Name" = "var.vpc_name"
  }
}


resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "name" = "var.igw_tag"
  }
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = data.aws_availability_zones.available_1.names[0]
  map_public_ip_on_launch = "true"
  tags = {
    "name" = "var.public_subnet_tag_1"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = data.aws_availability_zones.available_1.names[1]
  map_public_ip_on_launch = "true"
  tags = {
    "name" = "var.public_subnet_tag_2"
  }
}

resource "aws_subnet" "database_subnet_1" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = var.database_subnet_cidr_1
  availability_zone       = data.aws_availability_zones.available_1.names[3]
  map_public_ip_on_launch = false
  tags = {
    "name" = "var.database_subnet_tag_1"
  }
}
resource "aws_subnet" "database_subnet_2" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = var.database_subnet_cidr_2
  availability_zone       = data.aws_availability_zones.available_1.names[4]
  map_public_ip_on_launch = false
  tags = {
    "name" = "var.database_subnet_tag_2"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "name" = "var.public_route_table_tag"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myIGW.id
}


resource "aws_route_table" "database_route_table" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "name" = "var.database_route_table_tag"
  }
}


resource "aws_route_table_association" "public_route_table_assosiation_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_route_table_assosiation_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "database_route_table_assosiation_1" {
  subnet_id      = aws_subnet.database_subnet_1.id
  route_table_id = aws_route_table.database_route_table.id
}
resource "aws_route_table_association" "database_route_table_assosiation_2" {
  subnet_id      = aws_subnet.database_subnet_2.id
  route_table_id = aws_route_table.database_route_table.id
}


resource "aws_security_group" "sg" {
  name        = "security_group"
  description = "allow all inbound traffic"
  vpc_id      = aws_vpc.myVPC.id

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

resource "aws_instance" "test" {
  ami                    = data.aws_ami.amzllinux.id
  instance_type          = var.instance_type
  availability_zone      = data.aws_availability_zones.available_1.names[0]
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = "TF_key"
  tags = {
    "Name" = "ec2_instance"
  }
  
}

resource "aws_alb" "tcw_alb" {
  name = "tcw-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg.id]
  subnets = [aws_subnet.database_subnet_1.id, aws_subnet.database_subnet_2.id]
  enable_deletion_protection = false
  tags = {
    "Environment" = "Production"
  }
}

resource "aws_lb_target_group" "tcw_tg" {
  name = "tcw-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myVPC.id
}

resource "aws_lb_listener" "alb_forward_listner" {
  load_balancer_arn = aws_alb.tcw_alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.tcw_tg.arn
    type = "forward"
  }
}



resource "aws_launch_configuration" "lc" {
  name_prefix = "tcw_lc"
  image_id = data.aws_ami.amzllinux.id
  instance_type = var.asg_instnace
  key_name = "TF_key"
  associate_public_ip_address = true
  security_groups = [aws_security_group.sg.id]
  lifecycle {
    create_before_destroy = true 
  }
}
#resource "aws_autoscaling_group" "autoscaling_group" {
 # name = "tcw_autoscaling_group"
  #launch_configuration = aws_launch_configuration.lc.name
  #vpc_zone_identifier = [aws_subnet.public_subnet_1.id]
  #min_size = var.min_size
 # max_size = var.max_size
  #desired_capacity = var.desired_capacity
 #target_group_arns = [aws_lb_target_group.tcw_tg.arn]
 #tag {
   #key = "Name"
   #value = "tcw_wordpress_app_server"
  # propagate_at_launch = true
# }
# depends_on = [
#   aws_lb_target_group.tcw_tg, aws_lb_target_group.tcw_tg
# ]

#}


