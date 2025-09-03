terraform {
  backend "s3" {
    bucket         = "s3-backend-bucket-docker-sophika"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_locks_docker"
    encrypt        = true
  }
}

