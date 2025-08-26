terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# For production, use S3 backend:
# terraform {
#   backend "s3" {
#     bucket = "my-terraform-state"
#     key    = "qa/terraform.tfstate"
#     region = "us-east-1"
#   }
# }