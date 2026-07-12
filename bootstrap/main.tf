terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "state_bucket" {
  source  = "Infra-como-codigo-II-2026/s3-auy1105-grupo-6/aws"
  version = "~> 1.1.1"

  project            = "auy1105"
  environment        = "prod"
  bucket_suffix      = "tfstate-grupo-6"
  versioning_enabled = true
  create_lock_table  = true
}

output "state_bucket_name" {
  value = module.state_bucket.bucket_name
}

output "lock_table_name" {
  value = module.state_bucket.dynamodb_table_name
}