variable "env" {
  description = "Environment of deployment"
  type        = string
  default     = "test"
}
variable "region" {
  description = "AWS region for services"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "saved-files-7777"
}
