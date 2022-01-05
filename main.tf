# create terraform.tfvars with the following variables [access_key, secret_key, region, availability_zone]

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
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

variable "HOME" {
  type        = string
  description = "project home dir"
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

resource "aws_s3_bucket" "bucket" {
  bucket = "stop-instance"
  acl    = "private"
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "stop_instances.zip"
  acl    = "private"
  source = join("/", [var.HOME, "stop_instances.zip"])
  etag   = filemd5(join("/", [var.HOME, "stop_instances.zip"]))
}

resource "aws_lambda_function" "lambda" {
  role          = aws_iam_role.role.arn
  s3_bucket     = aws_s3_bucket.bucket.id
  s3_key        = "stop_instances.zip"
  function_name = "lambda-fn"
  handler       = "stop_instances.lambda_handler"
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
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::*"
            ]
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

output "server_id" {
  value = aws_instance.server.id
}