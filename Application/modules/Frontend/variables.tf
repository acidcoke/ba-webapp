variable "aws_region" {
  default = "eu-central-1"
}

variable "domain_name" {
  default = "headless.kiwi"
}

variable "website_bucket_name" {
  default = "headless.kiwi"
}

variable "base_url" {
  description = "Base URL for API Gateway stage."
}