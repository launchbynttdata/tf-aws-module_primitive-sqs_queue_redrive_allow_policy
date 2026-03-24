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

output "id" {
  description = "Queue URL from the primitive module (same as the DLQ URL when using the default example wiring)."
  value       = module.sqs_queue_redrive_allow_policy.id
}

output "queue_url" {
  description = "Queue URL from the primitive module output."
  value       = module.sqs_queue_redrive_allow_policy.queue_url
}

output "redrive_allow_policy" {
  description = "Redrive allow policy JSON from the primitive module output."
  value       = module.sqs_queue_redrive_allow_policy.redrive_allow_policy
}

output "dlq_url" {
  description = "URL of the dead-letter queue used in this example."
  value       = aws_sqs_queue.dlq.url
}

output "source_queue_url" {
  description = "URL of the source queue that redrives to the DLQ."
  value       = aws_sqs_queue.source.url
}

output "source_queue_arn" {
  description = "ARN of the source queue."
  value       = aws_sqs_queue.source.arn
}

output "sqs_server_side_encryption" {
  description = "SQS encryption mode in use (customer_managed_kms or sqs_managed)."
  value       = var.sqs_server_side_encryption
}

output "kms_key_id" {
  description = "KMS key ID when sqs_server_side_encryption is customer_managed_kms; empty string when sqs_managed."
  value       = length(aws_kms_key.sqs) > 0 ? aws_kms_key.sqs[0].id : ""
}

output "expected_redrive_allow_policy" {
  description = "Expected RedriveAllowPolicy JSON (matches module.sqs_queue_redrive_allow_policy.redrive_allow_policy)."
  value       = module.sqs_queue_redrive_allow_policy.redrive_allow_policy
}

output "aws_region" {
  description = "AWS Region where this example is deployed (use for SDK clients so they match the Terraform provider region)."
  value       = data.aws_region.current.name
}
