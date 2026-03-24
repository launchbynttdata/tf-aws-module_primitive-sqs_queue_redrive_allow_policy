resource_names_map = {
  dlq = {
    name       = "sqsdlq1"
    max_length = 80
  }
  source = {
    name       = "sqssrc1"
    max_length = 80
  }
  kms_alias = {
    name       = "kmsalsqs1"
    max_length = 240
  }
}

logical_product_family  = "launch"
logical_product_service = "sqsredrive"
class_env               = "dev"
instance_env            = 1
instance_resource       = 1
use_azure_region_abbr   = false

tags = {
  Example = "sqs_queue_redrive_allow_policy_complete"
}

sqs_server_side_encryption = "customer_managed_kms"

max_receive_count = 5
