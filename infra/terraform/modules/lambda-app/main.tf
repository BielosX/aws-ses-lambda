terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.7.0"
    }
  }
  backend "s3" {
    key = "lambda.tfstate"
  }
}

provider "aws" {}

module "ses" {
  source = "./ses"
  sandbox-to-email = var.sandbox-to-email
  ses-domain = var.ses-domain
}

module "lambda" {
  source = "./lambda"
  artifact-bucket-arn = var.artifact-bucket-arn
  artifact-name = var.artifact-name
  email-received-topic-arn = module.ses.email-received-topic-arn
  ses-domain = module.ses.ses-domain
}