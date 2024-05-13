# Output for Instance Public and Private IP address, Instance type, AMI type
output "instance_details" {
  value = {
    instance_public_ip  = aws_instance.ec2_instance.*.public_ip
    instance_private_ip = aws_instance.ec2_instance.*.private_ip
    instance_type       = var.instance_type
    ami_type            = var.use_linux ? "Amazon Linux 2" : "Windows"
  }
}

# Output for Subnet name and ID, subnet cidr
output "subnet_details" {
  value = {
    subnet_id   = aws_subnet.subnet.id
    subnet_name = var.subnet_type == "public" ? var.public_subnet_tag : var.private_subnet_tag
    subnet_cidr = var.subnet_type == "public" ? var.public_subnet_cidr : var.private_subnet_cidr
  }
}
