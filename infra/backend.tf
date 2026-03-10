terraform {
  backend "s3" {
    bucket         = "piyush169-chaos-resilience-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "piyush169-chaos-resilience-tflock"
    encrypt        = true
  }
}