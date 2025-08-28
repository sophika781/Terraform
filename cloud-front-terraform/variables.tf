variable "backend_bucket" {
  description = "Name of the backend bucket"
  type        = string
  default     = "s3-backend-bucket-sophika"
}

variable "terraform-lock" {
  description = "Name of the dynamo db table for acquire lock"
  type        = string
  default     = "terraform-locks"
}

variable "region" {
  description = "The region of that is hosting all the resources"
  type        = string
  default     = "us-east-1"
}

variable "hash_key" {
  description = "Hash key for the dynamo db table"
  type        = string
  default     = "LockID"
}

variable "s3_cloud_front_bucket" {
  description = "S3 bucket that holds all the static content"
  type        = string
  default     = "s3-cloud-front-bucket-sophika-2"
}

variable "s3_log_store_bucket" {
  description = "S3 bucket that holds all the logs for the s3 bucket"
  type        = string
  default     = "s3-log-store-sophika"
}

variable "days_transition_1" {
  description = "Number of days to transition to Glacier storage class"
  type        = number
  default     = 30
}

variable "days_transition_2" {
  description = "Number of days to transition to Deep Glacier storage class"
  type        = number
  default     = 120
}

variable "days_expiration" {
  description = "Number of days to expire objects (current and non current)"
  type        = number
  default     = 365
}