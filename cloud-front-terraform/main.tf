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
    id     = "s3-cloud-front-transition-delete"
    status = "Enabled"

    filter {
      prefix = ""
    }
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
    transition {
      days          = 120
      storage_class = "DEEP_ARCHIVE"
    }
    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
    noncurrent_version_transition {
      noncurrent_days = 120
      storage_class   = "DEEP_ARCHIVE"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "my-oac"
  description                       = "OAC for S3 bucket access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  comment             = "CloudFront Distribution to host static S3 bucket content"
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.s3-cloud-front-bucket-sophika-2.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

resource "aws_s3_bucket_policy" "cloud_front_bucket_policy" {
  bucket = aws_s3_bucket.s3-cloud-front-bucket-sophika-2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.s3-cloud-front-bucket-sophika-2.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}