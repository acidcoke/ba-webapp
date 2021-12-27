variable "aws_region" {
  default = "eu-central-1"
}

variable "name_prefix" {
  type = string
}

variable "website_bucket_name" {
  default = "ba.guestbook"
}

variable "api_route" {
  default = ""
}
