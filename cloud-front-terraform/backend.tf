terraform {
  backend "s3" {
    bucket         = "s3-backend-bucket-sophika"
    key            = "terraform.tfstate"
    dynamodb_table = "terraform-locks"
    region         = "us-east-1"
    encrypt        = true

  }
}