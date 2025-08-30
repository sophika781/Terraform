provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
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
  name   = var.ec2_security_group_name
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = var.ingress_to_port
    to_port     = var.ingress_to_port
    protocol    = var.ingress_protocol
    cidr_blocks = [var.ingress_cidr_block]
  }

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = var.ingress_protocol
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
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
    protocol    = var.ingress_protocol
    cidr_blocks = [var.ingress_cidr_block]
  }

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
    cidr_blocks = [var.egress_cidr_block]
  }
}

resource "aws_instance" "server_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.server_sg.id]
  subnet_id                   = aws_subnet.public_1.id
  key_name                    = "test-pair"
  associate_public_ip_address = true
  tags = {
    "Name" = var.instance_name
  }

  user_data = <<-EOF
    #!/bin/bash
        sudo su
        yum update -y
        yum install -y httpd
        echo "<html><body><h1>My Simple Webpage</h1></body></html>" > /var/www/html/index.html
        systemctl start httpd
        systemctl enable httpd
        EOF
}

resource "aws_ami_from_instance" "ami_from_ec2" {
  name               = "ami_from_ec2-terraform"
  source_instance_id = aws_instance.server_ec2.id
  depends_on         = [aws_instance.server_ec2]
}

resource "aws_launch_template" "my_launch_template" {
  name                   = "my-launch-template-terraform"
  image_id               = aws_ami_from_instance.ami_from_ec2.id
  instance_type          = var.instance_type
  key_name               = "test-pair"
  vpc_security_group_ids = [aws_security_group.server_sg.id]

  #user_data = base64encode(<<-EOF
  #      #!/bin/bash
  #      sudo su
  #      yum update -y
  #      yum install -y httpd
  #      echo "<html><body><h1>My Simple Webpage</h1></body></html>" > /var/www/html/index.html
  #      systemctl start httpd
  #      systemctl enable httpd
  #      EOF
  #)
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg-terraform"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
  }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb-terraform"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg-terraform"
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