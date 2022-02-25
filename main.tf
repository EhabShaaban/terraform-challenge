terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.0"
    }
  }
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

locals {
  common_tags = {
    Name    = "${var.name_tag_value}"
    Owner   = "${var.owner_tag_value}"
    Project = "${var.project_tag_value}"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone
  tags = {
    Name = "subnet"
  }
}

resource "aws_instance" "instance" {
  # Using Ubuntu Server 20.04 LTS (HVM), SSD Volume Type (64-bit x86)
  ami               = "ami-0892d3c7ee96c0bf7"
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = var.key_pair
  tags              = local.common_tags
}

module "bucket" {
  source        = "./modules/bucket"
  bucket_prefix = "server-"
  package_name  = "server.zip"
}

module "lambda" {
  source        = "./modules/lambda"
  bucket_id     = module.bucket.bucket_id
  s3_key        = "server.zip"
  function_name = "server-lambda"
  depends_on = [
    module.bucket
  ]
}

module "apigw" {
  source               = "./modules/apigw"
  uri                  = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}
