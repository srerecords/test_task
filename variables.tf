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
variable "service_name" {
  description = "Service name"
  type        = string
  default     = "copy_life_to_s3"
}

variable "lambda_relative_path" {
  description = "DO NOT CHANGE. This will be overridden by Terragrunt when needed."
  default     = "/./"
}
