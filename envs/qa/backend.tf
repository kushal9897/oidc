terraform {
  backend "s3" {
    bucket         = "terraform-state-<ACCOUNT_ID>"
    key            = "vault-ci-demo/qa/terraform.tfstate"
    region         = "<AWS_REGION>"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}