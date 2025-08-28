provider "aws" {
    region = "us-east-1"
    alias = "backend_setup"
}

resource "aws_s3_bucket" "s3_backend_bucket"{
    bucket = "s3-backend-bucket-sophika"
    acl = "private"
}

resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.s3_backend_bucket.id 

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_policy" "s3_backend_policy" {
  bucket = aws_s3_bucket.s3_backend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTerraformStateAccess"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::s3-backend-bucket-sophika/terraform.tfstate"
        ]
      }
    ]
  })
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
