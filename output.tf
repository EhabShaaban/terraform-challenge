output "instance_id" {
  value = aws_instance.instance.id
}

output "bucket_id" {
  value = module.bucket.bucket_id
}

output "invoke_stop_url" {
  value = module.apigw.stop
}

output "invoke_tags_url" {
  value = module.apigw.tags
}
