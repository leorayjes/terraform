# Terraform configuration block defining provider requirements and backend
terraform {
  required_version = ">= 1.0"
  
  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # S3 backend configuration for remote state storage
  # Note: Backend configuration should be initialized separately or via CLI
  backend "s3" {
    # These values should be configured during terraform init
    # bucket         = "your-terraform-state-bucket"
    # key            = "hackathon2/terraform.tfstate"
    # region         = "us-west-2"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}

# AWS provider configuration
provider "aws" {
  region = var.aws_region
  
  # Default tags applied to all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "hackathon2"
      ManagedBy   = "terraform"
      Workspace   = terraform.workspace
    }
  }
}