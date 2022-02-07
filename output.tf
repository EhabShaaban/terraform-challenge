output "stop" {
  value = aws_api_gateway_deployment.deploy_stop.invoke_url
}

output "tags" {
  value = aws_api_gateway_deployment.deploy_tags.invoke_url
}

output "instance_id" {
  value = aws_instance.instance.id
}
