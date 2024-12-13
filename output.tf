output "sagemaker_notebook_arn" {
  description = "The ARN of the SageMaker Notebook instance."
  value       = aws_sagemaker_notebook_instance.sagemaker_notebook.arn
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.hawa-abou1.bucket
}

output "dynamodb_table_terraform_lock" {
  description = "The ARN of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.te