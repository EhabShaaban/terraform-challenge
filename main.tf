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

resource "aws_s3_bucket" "bucket" {
  bucket = "stop-instance"
  acl    = "private"
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "server.zip"
  acl    = "private"
  source = "${path.module}/server.zip"
  etag   = filemd5("${path.module}/server.zip")
}

resource "aws_lambda_function" "lambda" {
  role          = aws_iam_role.role.arn
  s3_bucket     = aws_s3_bucket.bucket.id
  s3_key        = "server.zip"
  function_name = "lambda-fn"
  handler       = "server.lambda_handler"
  runtime       = "python3.6"
  timeout       = 180
  depends_on = [
    aws_s3_bucket.bucket,
    aws_s3_bucket_object.object
  ]
}

resource "aws_iam_policy" "policy" {
  name        = "lambda_access-policy"
  description = "IAM Policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "s3:*",
              "ec2:Stop*",
              "ec2:DescribeInstances",
              "ec2:DescribeTags"
            ],
            "Resource": "*"
        }
  ]
}
  EOF
}

resource "aws_iam_role" "role" {
  name               = "role"
  path               = "/"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam-policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
