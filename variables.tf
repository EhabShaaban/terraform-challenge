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

variable "name_tag_value" {
  type        = string
  description = "server name tag"
}

variable "owner_tag_value" {
  type        = string
  description = "server owner tag"
}

variable "project_tag_value" {
  type        = string
  description = "server project tag"
}

variable "key_pair" {
  type        = string
  description = "server key pair"
}

variable "bucket_prefix" {
  type        = string
  description = "Creates a unique bucket name"
}
