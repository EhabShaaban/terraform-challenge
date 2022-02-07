resource "aws_api_gateway_rest_api" "rest" {
  name = "serverless"
}

resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_rest_api.rest.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_method.root.resource_id
  http_method             = aws_api_gateway_method.root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_resource" "stop" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "stop"
}
resource "aws_api_gateway_method" "stop" {

  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.stop.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "stop_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_method.stop.resource_id
  http_method             = aws_api_gateway_method.stop.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_resource" "tags" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "tags"
}
resource "aws_api_gateway_method" "tags" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.tags.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tags_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_method.tags.resource_id
  http_method             = aws_api_gateway_method.tags.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy_stop" {
  depends_on = [
    aws_api_gateway_integration.stop_lambda,
    aws_api_gateway_integration.root,
  ]
  rest_api_id = aws_api_gateway_rest_api.rest.id
  stage_name  = "stop"
}

resource "aws_api_gateway_deployment" "deploy_tags" {
  depends_on = [
    aws_api_gateway_integration.tags_lambda,
    aws_api_gateway_integration.root,
  ]
  rest_api_id = aws_api_gateway_rest_api.rest.id
  stage_name  = "tags"
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
