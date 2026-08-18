terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # No remote backend on purpose: this is a single-environment demo
  # project. State is kept as local terraform.tfstate inside the Jenkins
  # workspace, which Jenkins reuses across builds of the same job/branch/
  # agent - so 'terraform plan' on the next build still sees what the
  # previous build created. This is NOT how you'd run Terraform for a real
  # team (state would live in a remote backend such as an S3 bucket +
  # DynamoDB lock table, provisioned once, out of band), but it avoids a
  # chicken-and-egg bootstrap problem for a single-bucket demo.
}

provider "aws" {
  region = var.aws_region
}

# Appended to bucket_name_prefix so the (globally unique, across all of
# AWS) bucket name doesn't collide with anyone else's.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "demo" {
  bucket = "${var.bucket_name_prefix}-${random_id.suffix.hex}"

  tags = {
    Project     = "app-terraform"
    ManagedBy   = "Jenkins"
    Environment = var.environment
  }
}
