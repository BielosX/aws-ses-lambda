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

module "emails-bucket" {
  source = "../private-bucket"
  name-prefix = "email-bucket"
  services-grant-put = ["ses.amazonaws.com"]
}

module "ses" {
  depends_on = [module.emails-bucket]
  source = "./ses"
  sandbox-to-email = var.sandbox-to-email
  ses-domain = var.ses-domain
  email-bucket-name = module.emails-bucket.bucket-name
}

module "lambda" {
  source = "./lambda"
  artifact-bucket-arn = var.artifact-bucket-arn
  artifact-name = var.artifact-name
  email-received-topic-arn = module.ses.email-received-topic-arn
  ses-domain = module.ses.ses-domain
  email-uploaded-topic-arn = module.ses.email-uploaded-topi-arn
}

module "api-gateway" {
  source = "./api-gateway"
  api-name = "email-api"
  welcome-lambda-arn = module.lambda.welcome-lambda-arn
}