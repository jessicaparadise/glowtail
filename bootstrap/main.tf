terraform {
    required_version = ">= 1.10"

    backend "s3" {
        bucket       = "glowtail-tfstate-988787367176"
        key          = "bootstrap/terraform.tfstate"
        region       = "us-east-1"
        use_lockfile = true
        encrypt      = true
  }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

# Who am I? (reads your AWS account ID)
data "aws_caller_identity" "current" {}

# The bucket that holds Terraform's memory
resource "aws_s3_bucket" "tf_state" {
  bucket = "glowtail-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

# Keep every old version of the state file
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt it at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Nobody on the internet gets in
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}