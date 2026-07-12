terraform {
  backend "s3" {
    bucket       = "auy1105-prod-tfstate-grupo-6"
    key          = "eft/grupo-6/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}