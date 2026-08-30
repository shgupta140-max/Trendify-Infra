terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket = "trendstore-infra-state"
    key    = "trendstore/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
