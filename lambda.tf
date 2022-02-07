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
