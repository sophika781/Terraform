provider "aws" {
  region = var.region
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    "Name" = var.main_vpc
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_cidr_block
  map_public_ip_on_launch = true

  tags = {
    "Name" = var.public_subnet
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    "Name" = "Internet Gateway"
  }

}

resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.private_cidr_block

  tags = {
    "Name" = var.private_subnet
  }
}

resource "aws_route_table" "private_table" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_table.id
}

resource "aws_network_acl" "private_nacl" {
  vpc_id     = aws_vpc.main_vpc.id
  subnet_ids = [aws_subnet.private_subnet.id]
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_cidr_block
    from_port  = 5432
    to_port    = 5432
  }
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_cidr_block
    from_port  = 1024
    to_port    = 65535
  }
}

resource "aws_security_group" "server_sg" {
  name        = var.security_group_name
  description = "Security group for the EC2 instance"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

}

resource "aws_instance" "server_ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  subnet_id              = aws_subnet.public_subnet.id
  tags = {
    "Name" = "server_ec2"
  }
  user_data = <<-EOF
        #!/bin/bash
        sudo su
        yum update -y
        amazon-linux-extras enable nginx1
        yum install -y nginx
        systemctl start nginx
        systemctl enable nginx
        EOF
}
