# create terraform.tfvars with the following variables [access_key, secret_key, region, availability_zone]

provider "aws" {
  access_key        = var.access_key
  secret_key        = var.secret_key
  region            = var.region
}

variable "access_key" {
  type        = string
  description = "aws access key"
}

variable "secret_key" {
  type        = string
  description = "aws secret key"
}

variable "region" {
  type        = string
  description = "aws region"
}

variable "availability_zone" {
  type        = string
  description = "server availability zone"
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

resource "aws_instance" "server" {
  ami               = "ami-0892d3c7ee96c0bf7"
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = "tf-challenge"

  tags = {
    Name  = "challenge accepted"
    Owner = "infra"
  }
}

output "server_id" {
  value = aws_instance.server.id
}