provider "aws" {
    region = var.region
}

resource "aws_s3_bucket" "s3-cloud-front-bucket-sophika-2" {
    bucket = var.s3_cloud_front_bucket
}

resource "aws_s3_bucket_versioning" "cloud_front_versioning" {
  bucket = aws_s3_bucket.s3-cloud-front-bucket-sophika-2.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.s3-cloud-front-bucket-sophika-2.id

  rule {
    id = "s3-cloud-front-transition-delete"
    status = "Enabled"

    filter {
        prefix = ""
    }
    transition {
      days= 30
      storage_class = "GLACIER"
    }
    transition {
      days = 120
      storage_class = "DEEP_ARCHIVE"
    }
    expiration {
      days= 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class = "GLACIER"
    }
    noncurrent_version_transition {
      noncurrent_days = 120
      storage_class = "DEEP_ARCHIVE"
    }
  }
}