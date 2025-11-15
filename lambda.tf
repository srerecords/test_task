locals {
  lambda_src_path = "${path.module}${var.lambda_relative_path}lambda"
}

# Create an archive form the Lambda source code,
# filtering out unneeded files.
data "archive_file" "lambda_source_package" {

  type       = "zip"
  source_dir = local.lambda_src_path
  #output_path = "${path.module}/.tmp/${random_uuid.lambda_src_hash.result}.zip"
  output_path = "${path.module}/.tmp/lambda_script.zip"

  # This is necessary, since archive_file is now a
  # `data` source and not a `resource` anymore.
  # Use `depends_on` to wait for the "install dependencies"
  # task to be completed.
}

# Create an IAM execution role for the Lambda function.
resource "aws_iam_role" "execution_role" {

  # IAM Roles are "global" resources. Lambda functions aren't.
  # In order to deploy the Lambda function in multiple regions
  # within the same account, separate Roles must be created.
  # The same Role could be shared across different Lambda functions,
  # but it's just not convenient to do so in Terraform.

  name = "lambda-execution-s3-copy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:sts::671402871606:assumed-role/cp-sts-grant-role/swift-eu-west-1-prod-132948732473"
      },
      "Effect": "Allow",
      "Sid": ""
    }        
  ]
}
EOF

  tags = {
    provisioner = "terraform"
  }
}

# Attach a IAM policy to the execution role to allow
# the Lambda to stream logs to Cloudwatch Logs.
resource "aws_iam_role_policy" "log_writer" {

  name = "lambda-log-writer-s3-copy"
  role = aws_iam_role.execution_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "es:*",
          "s3:*"
        ]
        "Resource" : "*",
        "Sid" : "AllowSpecifics"
      }
    ]
  })
}

# Deploy the Lambda function to AWS
resource "aws_lambda_function" "s3_copy" {
  function_name = "s3-copy"
  description   = "Lambda function fot copy files to S3 bucket."
  role          = aws_iam_role.execution_role.arn
  filename      = data.archive_file.lambda_source_package.output_path
  runtime       = "python3.9"
  handler       = "lambda.handler"
  memory_size   = 128
  timeout       = 30

  source_code_hash = data.archive_file.lambda_source_package.output_base64sha256

  tags = {
    Terraform   = true
    Environment = var.env
    Service     = var.service_name
  }

}

# The Lambda function would create this Log Group automatically
# at runtime if provided with the correct IAM policy, but
# we explicitly create it to set an expiration date to the streams.
resource "aws_cloudwatch_log_group" "s3_copy" {

  name              = "/aws/lambda/${aws_lambda_function.s3_copy.function_name}"
  retention_in_days = 30
}


# Triggering lambda
resource "aws_cloudwatch_event_rule" "s3_copy" {
  

  name                = aws_lambda_function.s3_copy.function_name
  description         = "Fires every 1 hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "s3_copy" {
  

  rule      = aws_cloudwatch_event_rule.s3_copy.name
  target_id = "lambda"
  arn       = aws_lambda_function.s3_copy.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_s3_copy" {
  

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_copy.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_copy.arn
}
