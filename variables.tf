variable "aws_region" {
  description = "AWS region to deploy the S3 bucket into."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for the generated bucket name; a random suffix is appended in main.tf so the (globally unique) S3 bucket name doesn't collide with anyone else's."
  type        = string
  default     = "dindo-app-terraform-demo"
}

variable "environment" {
  description = "Environment tag, set per-branch by the Jenkinsfile (dev/staging/prod)."
  type        = string
  default     = "dev"
}
