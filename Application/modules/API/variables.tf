variable "aws_region" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "headless.kiwi"
}

variable "website_bucket_name" {
  type    = string
  default = "headless.kiwi"
}

variable "mongodb_ingress_hostname" {
  type = string
}

variable "mongodb_secret" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "name_prefix" {
  type = string
}
