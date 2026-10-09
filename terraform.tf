# Configure the Terraform CLI and the providers this project requires.
terraform {
  # Declare the AWS provider dependency.
  required_providers {
    aws = {
      # Download the AWS provider maintained by HashiCorp.
      source = "hashicorp/aws"

      # Allow compatible AWS provider versions from 6.64 up to, but not including, 7.0.
      version = "~> 6.64"
    }
  }

  # Require Terraform CLI version 1.2 or later.
  required_version = ">= 1.2"
}