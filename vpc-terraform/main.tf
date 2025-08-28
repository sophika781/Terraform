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
    vpc_id= aws_vpc.main_vpc.id
    cidr_block = "10.0.0.0/24"

    tags = {
        "Name" = "public_vpc"
    }
}
