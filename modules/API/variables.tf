variable "aws_region" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "mongodb_ingress_hostname" {
  type = string
}

variable "mongodb_secret" {
  type = string
}

variable "website_bucket_name" {
  default = "ba.guestbook"
}
