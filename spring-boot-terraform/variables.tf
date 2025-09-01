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

variable "rds_password" {
  description = "Password for the RDS db instance"
  type        = string
  sensitive   = true
}