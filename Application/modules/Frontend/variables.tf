variable "aws_region" {
  default = "eu-central-1"
}

variable "domain_name" {
  default = "headless.kiwi"
}

variable "website_bucket_name" {
  default = "headless.kiwi"
}

variable "api_route" {
  default = ""
}

variable "name_prefix" {
  type = string
}
