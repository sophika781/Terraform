variable "region" {
  description = "region for the VPC"
  type        = string
  default     = "us-east-1"
}

variable "az_1" {
  description = "1st availability zone for the public, private subnet"
  type        = string
  default     = "us-east-1a"
}

variable "az_2" {
  description = "2nd availability for the public, private subnet"
  default     = "us-east-1b"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-00ca32bbc84273381"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidr_1" {
  description = "CIDR block for the 1st public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_cidr_2" {
  description = "CIDR block for the 2nd public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_cidr_1" {
  description = "CIDR block for the 1st private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_cidr_2" {
  description = "CIDR block for the 2nd private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "ingress_cidr_block" {
  description = "Inbound CIDR block for the security group"
  type        = string
  default     = "0.0.0.0/0"
}

variable "egress_cidr_block" {
  description = "Outbout CIDR block for the security group"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ec2_security_group_name" {
  description = "Name for the ec2 security group"
  type        = string
  default     = "ec2_sg"
}

variable "alb_security_group_name" {
  description = "Name for the alb security group"
  type        = string
  default     = "alb_sg"
}

variable "egress_from_port" {
  description = "Egress rule starting port"
  type        = number
  default     = 0
}

variable "egress_to_port" {
  description = "Egress rule ending port"
  type        = number
  default     = 0
}

variable "egress_protocol" {
  description = "Protocol for egress rule"
  type        = string
  default     = "-1"
}

variable "instance_name" {
  description = "Tag name for the instance"
  type        = string
  default     = "Spring Boot Server"
}

variable "rds_username" {
  description = "Username for the RDS database"
  type        = string
  default     = "pgadmin"
}

variable "rds_password" {
  description = "Password for the RDS db instance"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "mydb"
}

variable "key_pair" {
  description = "SSH key pair"
  type        = string
  default     = "test-pair"
}