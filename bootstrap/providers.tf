provider "aws" {
  region = var.aws_region
}

provider "vault" {
  address = var.vault_addr
  # Token will be provided via VAULT_TOKEN environment variable
}