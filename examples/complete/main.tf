// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  use_customer_managed_kms_for_sqs = var.sqs_server_side_encryption == "customer_managed_kms"

  default_redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.source.arn]
  })
}

resource "random_string" "kms_alias_suffix" {
  count = local.use_customer_managed_kms_for_sqs ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.0"

  for_each = var.resource_names_map

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  class_env               = var.class_env
  instance_env            = var.instance_env
  instance_resource       = var.instance_resource
  cloud_resource_type     = each.value.name
  maximum_length          = each.value.max_length

  region                = join("", split("-", data.aws_region.current.name))
  use_azure_region_abbr = var.use_azure_region_abbr
}

data "aws_iam_policy_document" "kms" {
  count = local.use_customer_managed_kms_for_sqs ? 1 : 0

  statement {
    sid    = "EnableAccountRoot"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSQS"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sqs.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "sqs" {
  count = local.use_customer_managed_kms_for_sqs ? 1 : 0

  description             = "CMK for SQS queues (complete example for sqs_queue_redrive_allow_policy)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "sqs" {
  count = local.use_customer_managed_kms_for_sqs ? 1 : 0

  name          = "alias/${module.resource_names["kms_alias"].standard}-${random_string.kms_alias_suffix[0].result}"
  target_key_id = aws_kms_key.sqs[0].key_id
}

resource "aws_sqs_queue" "dlq" {
  name                              = module.resource_names["dlq"].standard
  kms_master_key_id                 = local.use_customer_managed_kms_for_sqs ? aws_kms_key.sqs[0].id : null
  sqs_managed_sse_enabled           = local.use_customer_managed_kms_for_sqs ? null : true
  kms_data_key_reuse_period_seconds = local.use_customer_managed_kms_for_sqs ? 300 : null
  tags                              = var.tags
}

resource "aws_sqs_queue" "source" {
  name                              = module.resource_names["source"].standard
  kms_master_key_id                 = local.use_customer_managed_kms_for_sqs ? aws_kms_key.sqs[0].id : null
  sqs_managed_sse_enabled           = local.use_customer_managed_kms_for_sqs ? null : true
  kms_data_key_reuse_period_seconds = local.use_customer_managed_kms_for_sqs ? 300 : null
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
  tags = var.tags
}

module "sqs_queue_redrive_allow_policy" {
  source = "../.."

  queue_url            = coalesce(var.queue_url, aws_sqs_queue.dlq.url)
  redrive_allow_policy = coalesce(var.redrive_allow_policy, local.default_redrive_allow_policy)
}
