variable "region" {
  description = "Region"
  type        = string
  default     = "us-east-1"
}

variable "security_group_name" {
  description = "Name of the ec2 instance security group"
  type        = string
  default     = "ec2-security-group"
}

variable "vpc_cidr_block" {
  description = "CIDR Block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidr_block" {
  description = "CIDR Block for the public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_cidr_block" {
  description = "CIDR Block for the private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "main_vpc" {
  description = "Name for the main vpc"
  type        = string
  default     = "main_vpc"
}

variable "public_subnet" {
  description = "Name for the public subnet"
  type        = string
  default     = "public_subnet"
}

variable "private_subnet" {
  description = "Name for the private subnet"
  type        = string
  default     = "private_subnet"
}

variable "ami" {
  description = "AMI for the EC2 instance"
  type        = string
  default     = "ami-00ca32bbc84273381"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t3.micro"
}