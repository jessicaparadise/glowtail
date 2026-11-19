terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "glowtail-tfstate-988787367176"
    key          = "infra/terraform.tfstate"
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

  default_tags {
    tags = {
      Project   = "glowtail"
      ManagedBy = "terraform"
    }
  }
}