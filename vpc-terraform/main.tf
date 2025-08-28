provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "main_vpc"
    }
}

resource "aws_subnet" "main_public" {

}

resource "aws_subnet" "main_private" {

}

resource "aws_instance" "public_ec2" {

}

