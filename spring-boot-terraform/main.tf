provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name" = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name" = "Private Subnet 2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Internet-Gateway"
  }
}

resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_security_group" "server_sg" {
  name   = "server_sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }
  ingress {
    description = "Spring Boot"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db_sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "PostgreSQL"
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["10.0.0.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
  }
}

resource "aws_db_subnet_group" "private_group" {
  name       = "private_subnet_group_sophika"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "postgre_db" {
  engine            = "postgres"
  engine_version    = "17.6"
  identifier        = "postgres-rds"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  username = "pgadmin"
  password = var.rds_password

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_group.name
  skip_final_snapshot    = true
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_s3_readonly_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.server_sg.id]
  key_name                    = "test-pair"
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    "Name" = var.instance_name
  }

  user_data = <<-EOF
        #!/bin/bash
        set -xe
        sudo yum update -y
        sudo yum install -y java-17-amazon-corretto-headless awscli
        aws s3 cp s3://s3-backend-bucket-sophika/spring-petclinic-3.5.0-SNAPSHOT.jar /home/ec2-user/myapp.jar
        sudo chown ec2-user:ec2-user /home/ec2-user/myapp.jar
        sudo tee /etc/systemd/system/myapp.service > /dev/null <<EOL
        [Unit]
        Description=Spring Boot Application
        After=network.target

        [Service]
        User=ec2-user
        ExecStart=/usr/bin/java -jar /home/ec2-user/myapp.jar
        Restart=always
        RestartSec=5
        StandardOutput=file:/home/ec2-user/app.log
        StandardError=file:/home/ec2-user/app-error.log

        [Install]
        WantedBy=multi-user.target
        EOL
        sudo systemctl daemon-reload
        sudo systemctl enable myapp
        sudo systemctl start myapp
    EOF
}

resource "aws_ami_from_instance" "app_ami" {
  name               = "EC2 AMI"
  source_instance_id = aws_instance.app_server.id
  depends_on         = [aws_instance.app_server]

  #provisioner "remote-exec" {
  #  inline = [
  #    "while [ ! -f /tmp/app_ready ]; do sleep 5; done"
  #  ]

  #  connection {
  #    type        = "ssh"
  #    host        = aws_instance.app_server.public_ip
  #    user        = "ec2-user"
  #    private_key = file("~/.ssh/test-pair.pem")
  #  }
  #}
}

resource "aws_instance" "test_ec2" {
  ami                    = aws_ami_from_instance.app_ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  tags = {
    "Name" = "Second Server"
  }
}



