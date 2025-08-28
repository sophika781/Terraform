provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "main_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    "Name" = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    "Name" = "private_subnet"
  }
}

resource "aws_security_group" "server_sg" {
  description = "Security group for the EC2 instance"

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
  ami                    = "ami-00ca32bbc84273381"
  instance_type          = "t3.micro"
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