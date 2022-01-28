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
    Owner   = "infra"
    Name    = "AutoStop"
    Project = "challenge accepted"
  }
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
              "ec2:DescribeInstances"
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

resource "aws_api_gateway_rest_api" "rest" {
  name = "Serverless"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_rest_api.rest.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_method.proxy_root.resource_id
  http_method             = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy_rest" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  rest_api_id = aws_api_gateway_rest_api.rest.id
  stage_name  = "stop"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.rest.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.deploy_rest.invoke_url
}

output "server_id" {
  value = aws_instance.server.id
}
