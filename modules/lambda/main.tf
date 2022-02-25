resource "aws_lambda_function" "lambda" {
  role          = aws_iam_role.role.arn
  s3_bucket     = var.bucket_id
  s3_key        = var.s3_key
  function_name = var.function_name
  handler       = "server.lambda_handler"
  runtime       = "python3.6"
  timeout       = 180
}

resource "aws_iam_role_policy_attachment" "iam-policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
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
