terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "profile" {
  type    = string
  default = "default"
}

variable "bucket_name" {
  type        = string
  description = "Nome global do bucket S3 — precisa ser único na AWS"
}

variable "glue_database" {
  type    = string
  default = "anp_fuel_prices"
}

locals {
  common_tags = {
    project   = "anp-fuel-prices"
    owner     = "ildean"
    env       = "portfolio"
    managedBy = "terraform"
    repo      = "projetos-engineer-git"
  }
}

resource "aws_s3_bucket" "raw" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.bucket_name}-athena-results"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_glue_catalog_database" "anp" {
  name = var.glue_database
}

resource "aws_athena_workgroup" "anp" {
  name = "wg-anp-fuel-prices"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }

  force_destroy = true
  tags          = local.common_tags
}

output "raw_bucket" {
  value = aws_s3_bucket.raw.bucket
}

output "raw_bucket_arn" {
  value = aws_s3_bucket.raw.arn
}

output "glue_database" {
  value = aws_glue_catalog_database.anp.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.anp.name
}
