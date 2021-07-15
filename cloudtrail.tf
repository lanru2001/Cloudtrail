data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "urlib_cloudtrail" {
  name                          = "${var.namespace}-cloudtrail-${var.stage}"
  s3_bucket_name                = aws_s3_bucket.uclib_cloudtrail_bucket.bucket   #"${var.namespace}-cloudtrail-${var.stage}" 
  s3_key_prefix                 = "prefix"
  include_global_service_events = false 
  tags    = {
    Name  = "${local.environment_prefix}-cloudtrail"
  }
}

#resource "aws_kms_key" "app_trail_key" {
#  description             = "This key is used to encrypt bucket objects"
#  deletion_window_in_days = 30
#}

resource "aws_s3_bucket" "app_cloudtrail_bucket" {
  bucket        = "${var.namespace}-cloudtrail-${var.stage}"
  force_destroy = true
  versioning {
    enabled = true
  }
  
 # server_side_encryption_configuration {
 #   rule {
 #     apply_server_side_encryption_by_default {
 #       kms_master_key_id = aws_kms_key.uclib_trail_key.arn
 #       sse_algorithm     = "aws:kms"
 #     }
 #   }
 # }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.namespace}-cloudtrail-${var.stage}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.namespace}-cloudtrail-${var.stage}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_block" {

  bucket = aws_s3_bucket.uclib_cloudtrail_bucket.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}
