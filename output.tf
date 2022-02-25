output "instance_id" {
  value = aws_instance.instance.id
}

output "stop" {
  value = module.apigw.stop
}

output "tags" {
  value = module.apigw.tags
}
