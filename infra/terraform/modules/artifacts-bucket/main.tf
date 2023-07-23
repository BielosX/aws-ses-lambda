terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.7.0"
    }
  }
  backend "s3" {
    key = "artifacts-bucket.tfstate"
  }
}

provider "aws" {}

module "private-bucket" {
  source = "../private-bucket"
  name-prefix = "artifacts"
}