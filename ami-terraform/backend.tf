terraform {
  backend "s3" {
    bucket = "s3-ami-bucket-sophika"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
} 
