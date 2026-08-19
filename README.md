# tf-aws-module_primitive-sqs_queue_redrive_allow_policy

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

## Overview

Terraform primitive module that wraps a single [`aws_sqs_queue_redrive_allow_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) resource. Use it on a dead-letter queue to declare which source queues may redrive messages back from that DLQ (for example `redrivePermission = "byQueue"` and `sourceQueueArns`).

## Usage

```hcl
module "dlq_redrive_allow" {
  source = "path-or-registry-to-this-module"

  queue_url = aws_sqs_queue.dlq.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.source.arn]
  })
}
```

A full example (KMS-encrypted source and DLQ, resource naming module, Terratest) lives under [`examples/complete`](./examples/complete/).

## Contributing

Run `make configure` from the repository root to sync shared automation before using `make` targets. Provider configuration is not committed in modules; the build generates `provider.tf` in examples where applicable.

For Terraform documentation embedded below, use `terraform-docs` or rely on the pre-commit hook that updates the marked section.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sqs_queue_redrive_allow_policy.queue_redrive_allow_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_queue_url"></a> [queue\_url](#input\_queue\_url) | URL of the SQS queue to which the redrive allow policy is attached (typically a dead-letter queue). | `string` | n/a | yes |
| <a name="input_redrive_allow_policy"></a> [redrive\_allow\_policy](#input\_redrive\_allow\_policy) | JSON document defining which source queues may use this queue as a dead-letter queue and redrive messages back.<br/>See the Amazon SQS dead-letter queue documentation for the schema (for example redrivePermission and sourceQueueArns). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The URL of the SQS queue (same as queue\_url). |
| <a name="output_queue_url"></a> [queue\_url](#output\_queue\_url) | The URL of the SQS queue to which the redrive allow policy is attached. |
| <a name="output_redrive_allow_policy"></a> [redrive\_allow\_policy](#output\_redrive\_allow\_policy) | The redrive allow policy JSON applied to the queue. |
<!-- END_TF_DOCS -->
