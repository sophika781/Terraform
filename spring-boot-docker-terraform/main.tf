provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr_1
  availability_zone = var.az_1
  tags = {
    "Name" = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr_2
  availability_zone = var.az_2
  tags = {
    "Name" = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_1
  availability_zone = var.az_1
  tags = {
    "Name" = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_2
  availability_zone = var.az_2
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
  name   = "server_sg_docker"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
  name   = "db_sg_docker"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "PostgreSQL"
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = [var.public_cidr_1, var.public_cidr_2]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
  }
}

resource "aws_security_group" "alb_sg" {
  name   = var.alb_security_group_name
  vpc_id = aws_vpc.main.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
    cidr_blocks = [var.egress_cidr_block]
  }
}

resource "aws_db_subnet_group" "private_group" {
  name       = "private_subnet_group_sophika_docker"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "postgre_db" {
  engine            = "postgres"
  engine_version    = "17.6"
  identifier        = "postgres-rds-docker"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp2"

  username = var.rds_username
  password = var.rds_password
  db_name  = var.db_name

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_group.name
  skip_final_snapshot    = true
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-role-docker"

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
  name = "ec2_s3_readonly_profile_docker"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.server_sg.id]
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  depends_on                  = [aws_db_instance.postgre_db]
  tags = {
    "Name" = var.instance_name
  }

  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y java-17-amazon-corretto-headless
        sudo dnf install -y postgresql17
        sudo yum install docker -y
        sudo service docker start
        sudo systemctl enable docker
        sudo systemctl start docker
        docker pull sophika171g/myapp:latest
        docker run -d -p 8080:8080 sophika171g/myapp:latest
    EOF
}

resource "aws_ami_from_instance" "app_ami" {
  name               = "EC2 AMI Docker"
  source_instance_id = aws_instance.app_server.id
  depends_on         = [aws_instance.app_server]
}

resource "aws_launch_template" "my_launch_template" {
  name          = "my-launch-template-docker"
  image_id      = aws_ami_from_instance.app_ami.id
  instance_type = var.instance_type
  key_name      = var.key_pair
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.server_sg.id]
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg-terraform-docker"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/actuator/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
  }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb-terraform-docker"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg-terraform-docker"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 3
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  health_check_type   = "EC2"
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"

  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]
  depends_on        = [aws_launch_template.my_launch_template]
}
