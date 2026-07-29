# backend.tf
terraform {
  backend "s3" {
    bucket         = "tform-bkt-66"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "tform-locks"
    encrypt        = true
  }
}