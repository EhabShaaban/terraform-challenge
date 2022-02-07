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
