terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "my-terraform-state-08e6a14d"
    key            = "test-course/s3/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
    
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}