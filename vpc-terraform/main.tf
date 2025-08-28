provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "main_vpc"
  }
}

resource "aws_subnet" "public_vpc" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    "Name" = "public_vpc"
  }
}

resource "aws_subnet" "private_vpc" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    "Name" = "private_vpc"
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

