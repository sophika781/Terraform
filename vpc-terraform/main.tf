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
  availability_zone       = "us-east-1a"
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
  tags = {
    "Name" = "Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_cidr_block
  availability_zone = "us-east-1a"

  tags = {
    "Name" = var.private_subnet
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_cidr_block_2
  availability_zone = "us-east-1b"

  tags = {
    "Name" = var.private_subnet_2
  }
}

resource "aws_route_table" "private_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    "Name" = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_table.id
}

resource "aws_security_group" "server_sg" {
  name        = var.server_security_group_name
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

  tags = {
    "Name" = "EC2 server security group"
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

resource "aws_security_group" "db_sg" {
  name        = var.db_security_group_name
  description = "Security group for the EC2 instance"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  tags = {
    "Name" = "DB security group"
  }

}

resource "aws_db_subnet_group" "private_group" {
  name       = "private_subnet_group_sophika"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id]
}

resource "aws_db_instance" "postgresql_rds" {
  engine            = "postgres"
  engine_version    = "17.6"
  identifier        = "postgres-rds"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  username = "postgres-admin"
  password = var.rds_password

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_group.name
}