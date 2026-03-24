# Complete example: `aws_sqs_queue_redrive_allow_policy`

This example provisions SQS source and dead-letter queues with encryption controlled by `sqs_server_side_encryption` (customer-managed KMS or SQS-managed SSE—mutually exclusive in `aws_sqs_queue`). It attaches a redrive allow policy on the DLQ and calls the root module with all supported inputs.

## Usage

Configure AWS credentials and a default region, run `make configure` if your workflow generates `provider.tf`, then:

```shell
cd examples/complete
terraform init
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```

## Example Terraform (`main.tf`)

The snippet below matches [`main.tf`](./main.tf) (excluding the license header).

```hcl
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
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 2.0 |
| <a name="module_sqs_queue_redrive_allow_policy"></a> [sqs\_queue\_redrive\_allow\_policy](#module\_sqs\_queue\_redrive\_allow\_policy) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_sqs_queue.dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [random_string.kms_alias_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | Map of keys to resource\_name module settings (cloud\_resource\_type must be alphanumeric only). | <pre>map(object({<br/>    name       = string<br/>    max_length = optional(number, 80)<br/>  }))</pre> | n/a | yes |
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | Logical product family for resource naming. | `string` | n/a | yes |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | Logical product service for resource naming. | `string` | n/a | yes |
| <a name="input_class_env"></a> [class\_env](#input\_class\_env) | Environment classification for resource naming. | `string` | n/a | yes |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Instance environment number (0–999) for resource naming. | `number` | n/a | yes |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Instance resource number (0–100) for resource naming. | `number` | n/a | yes |
| <a name="input_use_azure_region_abbr"></a> [use\_azure\_region\_abbr](#input\_use\_azure\_region\_abbr) | Whether to use Azure-style region abbreviation in resource names (set false for AWS examples). | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to created AWS resources. | `map(string)` | `{}` | no |
| <a name="input_sqs_server_side_encryption"></a> [sqs\_server\_side\_encryption](#input\_sqs\_server\_side\_encryption) | How to encrypt the example SQS queues. These values map to mutually exclusive aws\_sqs\_queue arguments:<br/>customer\_managed\_kms sets kms\_master\_key\_id (and must not set sqs\_managed\_sse\_enabled);<br/>sqs\_managed sets sqs\_managed\_sse\_enabled only (and must not set kms\_master\_key\_id). | `string` | `"customer_managed_kms"` | no |
| <a name="input_queue_url"></a> [queue\_url](#input\_queue\_url) | When set, attaches the primitive module to this queue URL instead of the DLQ created in this example. | `string` | `null` | no |
| <a name="input_redrive_allow_policy"></a> [redrive\_allow\_policy](#input\_redrive\_allow\_policy) | When set, uses this JSON string as the redrive allow policy instead of the default derived from the source queue ARN. | `string` | `null` | no |
| <a name="input_max_receive_count"></a> [max\_receive\_count](#input\_max\_receive\_count) | Maximum receives before a message is sent to the dead-letter queue (source queue redrive policy). | `number` | `5` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Queue URL from the primitive module (same as the DLQ URL when using the default example wiring). |
| <a name="output_queue_url"></a> [queue\_url](#output\_queue\_url) | Queue URL from the primitive module output. |
| <a name="output_redrive_allow_policy"></a> [redrive\_allow\_policy](#output\_redrive\_allow\_policy) | Redrive allow policy JSON from the primitive module output. |
| <a name="output_dlq_url"></a> [dlq\_url](#output\_dlq\_url) | URL of the dead-letter queue used in this example. |
| <a name="output_source_queue_url"></a> [source\_queue\_url](#output\_source\_queue\_url) | URL of the source queue that redrives to the DLQ. |
| <a name="output_source_queue_arn"></a> [source\_queue\_arn](#output\_source\_queue\_arn) | ARN of the source queue. |
| <a name="output_sqs_server_side_encryption"></a> [sqs\_server\_side\_encryption](#output\_sqs\_server\_side\_encryption) | SQS encryption mode in use (customer\_managed\_kms or sqs\_managed). |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | KMS key ID when sqs\_server\_side\_encryption is customer\_managed\_kms; empty string when sqs\_managed. |
| <a name="output_expected_redrive_allow_policy"></a> [expected\_redrive\_allow\_policy](#output\_expected\_redrive\_allow\_policy) | Expected RedriveAllowPolicy JSON (matches module.sqs\_queue\_redrive\_allow\_policy.redrive\_allow\_policy). |
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS Region where this example is deployed (use for SDK clients so they match the Terraform provider region). |
<!-- END_TF_DOCS -->
