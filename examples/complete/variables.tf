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

variable "resource_names_map" {
  description = "Map of keys to resource_name module settings (cloud_resource_type must be alphanumeric only)."
  type = map(object({
    name       = string
    max_length = optional(number, 80)
  }))
}

variable "logical_product_family" {
  description = "Logical product family for resource naming."
  type        = string
}

variable "logical_product_service" {
  description = "Logical product service for resource naming."
  type        = string
}

variable "class_env" {
  description = "Environment classification for resource naming."
  type        = string
}

variable "instance_env" {
  description = "Instance environment number (0–999) for resource naming."
  type        = number
}

variable "instance_resource" {
  description = "Instance resource number (0–100) for resource naming."
  type        = number
}

variable "use_azure_region_abbr" {
  description = "Whether to use Azure-style region abbreviation in resource names (set false for AWS examples)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to created AWS resources."
  type        = map(string)
  default     = {}
}

variable "sqs_server_side_encryption" {
  description = <<-EOT
    How to encrypt the example SQS queues. These values map to mutually exclusive aws_sqs_queue arguments:
    customer_managed_kms sets kms_master_key_id (and must not set sqs_managed_sse_enabled);
    sqs_managed sets sqs_managed_sse_enabled only (and must not set kms_master_key_id).
  EOT
  type        = string
  default     = "customer_managed_kms"

  validation {
    condition     = contains(["customer_managed_kms", "sqs_managed"], var.sqs_server_side_encryption)
    error_message = "sqs_server_side_encryption must be customer_managed_kms or sqs_managed."
  }
}

variable "queue_url" {
  description = "When set, attaches the primitive module to this queue URL instead of the DLQ created in this example."
  type        = string
  default     = null
}

variable "redrive_allow_policy" {
  description = "When set, uses this JSON string as the redrive allow policy instead of the default derived from the source queue ARN."
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "Maximum receives before a message is sent to the dead-letter queue (source queue redrive policy)."
  type        = number
  default     = 5

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}
