terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "aws_region" {
  type        = string
  description = "AWS region (GuardDuty is regional)"
}

variable "bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for GuardDuty export"
}

variable "project" {
  type        = string
  description = "Tagging: project name"
  default     = "guardduty-export"
}

variable "environment" {
  type        = string
  description = "Tagging: env (dev/uat/prod)"
  default     = "prod"
}

variable "kms_admin_arns" {
  type        = list(string)
  description = "Optional IAM ARNs that can administer the KMS key"
  default     = []
}

variable "destination_prefix" {
  type        = string
  description = "Optional S3 prefix (folder) for GuardDuty exports, e.g. 'guardduty/'"
  default     = "guardduty/"
}

locals {
  account_id          = data.aws_caller_identity.current.account_id
  guardduty_principal = "guardduty.amazonaws.com"
  normalized_prefix   = trim(var.destination_prefix, "/")
  destination_arn = local.normalized_prefix != ""
    ? "arn:aws:s3:::${var.bucket_name}/${local.normalized_prefix}/"
    : "arn:aws:s3:::${var.bucket_name}"
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid     = "AllowAccountRootFullAccess"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.kms_admin_arns) > 0 ? [1] : []
    content {
      sid    = "AllowKeyAdmins"
      effect = "Allow"
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ]

      principals {
        type        = "AWS"
        identifiers = var.kms_admin_arns
      }

      resources = ["*"]
    }
  }

  statement {
    sid    = "AllowGuardDutyEncryptFindings"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = [local.guardduty_principal]
    }

    resources = ["*"]
  }
}

resource "aws_kms_key" "guardduty_export" {
  description             = "KMS key for GuardDuty findings export bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "guardduty_export" {
  name          = "alias/${var.project}-${var.environment}-guardduty-export"
  target_key_id = aws_kms_key.guardduty_export.key_id
}

resource "aws_s3_bucket" "guardduty_bucket" {
  bucket = var.bucket_name

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.guardduty_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.guardduty_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.guardduty_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.guardduty_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.guardduty_export.arn
    }
    bucket_key_enabled = true
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.guardduty_bucket.arn,
      "${aws_s3_bucket.guardduty_bucket.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid     = "AllowGuardDutyPutObject"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.guardduty_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = [local.guardduty_principal]
    }
  }

  statement {
    sid     = "AllowGuardDutyGetBucketLocation"
    effect  = "Allow"
    actions = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.guardduty_bucket.arn]

    principals {
      type        = "Service"
      identifiers = [local.guardduty_principal]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.guardduty_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_guardduty_detector" "this" {}

resource "aws_guardduty_publishing_destination" "to_s3" {
  detector_id     = data.aws_guardduty_detector.this.id
  destination_arn = local.destination_arn
  kms_key_arn     = aws_kms_key.guardduty_export.arn

  depends_on = [aws_s3_bucket_policy.this]
}

output "bucket_name" {
  value = aws_s3_bucket.guardduty_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.guardduty_bucket.arn
}

output "kms_key_arn" {
  value = aws_kms_key.guardduty_export.arn
}

output "kms_alias" {
  value = aws_kms_alias.guardduty_export.name
}

output "publishing_destination_id" {
  value = aws_guardduty_publishing_destination.to_s3.id
}

output "publishing_destination_arn" {
  value = aws_guardduty_publishing_destination.to_s3.destination_arn
}
