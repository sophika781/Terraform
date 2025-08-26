provider "aws" {
  region = "us-east-1"
  profile = "ec2-user"
}

resource "tls_private_key" "key-pair" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "key-pair" {
  key_name   = "key-pair"
  public_key = tls_private_key.key-pair.public_key_openssh
}

output "private_key_pem" {
  value = tls_private_key.key-pair.private_key_pem
  sensitive = true
}

resource "aws_security_group" "server-sg" {
  description = "Security group for the EC2 instance"
  egress {
            cidr_blocks = ["0.0.0.0/0"]
            from_port        = 0
            protocol         = "-1"
            to_port          = 0
    }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
            description      = null
            from_port        = -1
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "icmp"
            security_groups  = []
            self             = false
            to_port          = -1
  }
  ingress {
      cidr_blocks = ["0.0.0.0/0"]
            description      = null
            from_port        = 22
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
            to_port          = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
            description      = null
            from_port        = 80
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
            to_port          = 80
  }
}
  

resource "aws_instance" "ec2-server" {
  ami = "ami-00ca32bbc84273381"
  instance_type = "t3.micro"
  key_name = aws_key_pair.key-pair.key_name
  tags = {
    "Name" = "ec2-server"
  }
  vpc_security_group_ids = ["sg-0e26dc65acfe7f85a"]

}
