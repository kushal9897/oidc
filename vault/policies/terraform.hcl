# Policy for Terraform to read AWS credentials
path "aws/creds/terraform-role" {
  capabilities = ["read"]
}

path "aws/sts/terraform-role" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}