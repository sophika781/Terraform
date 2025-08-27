terraform {
    backend "s3" {
        bucket = "s3_backend_bucket"
        key = "terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform_lock"
        encrypt = true
    }
}
