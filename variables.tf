variable "region" {
  type        = string
  default     = "us-west-2"
  description = "aws region"
}

variable "availability_zone" {
  type        = string
  default     = "us-west-2a"
  description = "server availability zone"
}

variable "name_tag_value" {
  # This will need to be changed also in server.py
  type        = string
  default     = "auto stop"
  description = "server name tag"
}

variable "owner_tag_value" {
  type        = string
  default     = "infra"
  description = "server owner tag"
}

variable "project_tag_value" {
  type        = string
  default     = "challenge accepted!"
  description = "server project tag"
}

variable "key_pair" {
  type        = string
  default     = "tf-challenge"
  description = "server key pair"
}

variable "bucket_prefix" {
  type        = string
  description = "Creates a unique bucket name"
}
