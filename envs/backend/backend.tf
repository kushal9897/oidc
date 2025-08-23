terraform {
  backend "s3" {
    bucket         = "terraform-state-863518457874"
    key            = "vault-ci-demo/backend/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}