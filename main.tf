terraform {
  backend "s3" {
    bucket         = "hawa-abou1"
    key            = "terraform/sagemaker/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table for Terraform Locking
resource "aws_dynamodb_table" "terraform-lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Define the S3 Bucket
resource "aws_s3_bucket" "hawa-abou1" {
  bucket = "hawa-abou1"
}

# Configure Versioning on the S3 Bucket
resource "aws_s3_bucket_versioning" "hawa-abou1-versioning" {
  bucket = aws_s3_bucket.hawa-abou1.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Resource for server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.hawa-abou1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for SageMaker
resource "aws_iam_role" "sagemaker_role" {
  name = "sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy Attachment for S3 and SageMaker Permissions
resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# SageMaker Notebook Instance Lifecycle Configuration
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "lifecycle_config" {
  name = "sagemaker-lifecycle-config"

  on_create = base64encode(<<EOF
#!/bin/bash
set -e
echo "Running on-create script" > /var/log/on-create.log
EOF
  )

  on_start = base64encode(<<EOF
#!/bin/bash
set -e
echo "Running on-start script" > /var/log/on-start.log
EOF
  )
}

# SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "sagemaker_notebook" {
  name                  = "sagemaker-production-notebook"
  instance_type         = "ml.t2.medium"
  role_arn              = aws_iam_role.sagemaker_role.arn
  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.lifecycle_config.name

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
resource "random_id" "notebook_suffix" {
  byte_length = 8
}
