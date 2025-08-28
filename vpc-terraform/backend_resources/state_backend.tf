provider "aws" {
    region = "us-east-1"
    alias = "backend_setup"
}

resource "aws_s3_bucket" "s3_backend_bucket"{
    bucket = "s3-backend-bucket-sophika"
}

resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.s3_backend_bucket.id 

    versioning_configuration {
        status = Enabled
    }
}

resource "aws_dynamodb_table" "terraform_lock" {
    name = "terraform_lock"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}
