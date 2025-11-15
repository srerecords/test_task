module "s3_logs_bucket" {

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v3.4.0"

  # dynamic cretion is supported by the root module
  create_bucket = true

  bucket = var.bucket_name

  force_destroy = true

  attach_policy        = false
  attach_public_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "remove_old_files"
      enabled = true
      prefix  = ""


      expiration = {
        days = 7
      }

    }
  ]
  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Terraform   = true
    Environment = var.env
    Name        = var.bucket_name
    Service     = var.service_name
  }
}
