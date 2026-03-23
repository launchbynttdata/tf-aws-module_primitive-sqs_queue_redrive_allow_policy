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
  description = "The URL of the SQS queue (same as queue_url)."
  value       = aws_sqs_queue_redrive_allow_policy.queue_redrive_allow_policy.id
}

output "queue_url" {
  description = "The URL of the SQS queue to which the redrive allow policy is attached."
  value       = aws_sqs_queue_redrive_allow_policy.queue_redrive_allow_policy.queue_url
}

output "redrive_allow_policy" {
  description = "The redrive allow policy JSON applied to the queue."
  value       = aws_sqs_queue_redrive_allow_policy.queue_redrive_allow_policy.redrive_allow_policy
}
