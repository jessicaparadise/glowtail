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

# Budget to keep costs under control
resource "aws_budgets_budget" "monthly" {
  name         = "monthly-account-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["jessica.paradise@protonmail.com"]
  }
}

# GitHub Actions OIDC trust relationship
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# GitHub Actions can become this role
data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    # Only allow GitHub Actions to assume this role if the request comes from the GitHub OIDC provider
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    # Only allow GitHub Actions to assume this role if the audience is sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # This is the important part - only allow the main branch and PRs from the same repo
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:jessicaparadise@213542472/glowtail@1448658514:ref:refs/heads/main",
        "repo:jessicaparadise@213542472/glowtail@1448658514:pull_request"
      ]
    }
  }
}

# The role GitHub Actions becomes when it runs
resource "aws_iam_role" "github_actions" {
  name               = "glowtail-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# What the pipeline role is allowed to do (broad for now, will tighten later)
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# The role ARN that GitHub Actions needs
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}