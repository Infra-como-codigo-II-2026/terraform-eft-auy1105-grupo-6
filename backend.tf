terraform {
  backend "s3" {
    bucket         = "REEMPLAZAR-con-output-state_bucket_name-de-bootstrap"
    key            = "eft/grupo-6/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "REEMPLAZAR-con-output-lock_table_name-de-bootstrap"
  }
}