provider "aws" {
	region = "us-east-1"
}

resource "aws_security_group" "server_sg" {
	description = "Security group for both web servers"
	ingress {
		description = "SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "dev_ec2" {
	ami = "ami-00ca32bbc84273381"
	instance_type = "t3.micro"
	vpc_security_group_ids = [aws_security_group.server_sg.id]
	tags = {
		"Name" = "dev_ec2"
		"Environment" = "Dev"
	}
}

resource "aws_ami_from_instance" "image_from_dev" {
  name               = "image_from_dev"
  source_instance_id = aws_instance.dev_ec2.id

  tags = {
    "Environment" = "Prod"
  }
}

resource "aws_instance" "prod_ec2" {
  ami = aws_ami_from_instance.image_from_dev.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  tags = {
    "Name" = "prod_ec2"
    "Environment" = "Prod"
  }
}

