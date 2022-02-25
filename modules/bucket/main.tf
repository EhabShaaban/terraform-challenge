resource "aws_s3_bucket" "bucket" {
  bucket_prefix = var.bucket_prefix
  acl           = "private"
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = var.package_name
  acl    = "private"
  source = "./${var.package_name}"
  etag   = filemd5("./${var.package_name}")
}
