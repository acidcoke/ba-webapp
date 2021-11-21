variable "aws_region" {
  default = "eu-central-1"
}

variable "domain_name" {
  default = "headless.kiwi"
}

variable "website_bucket_name" {
  default = "headless.kiwi"
}

variable "mongodb_ingress_hostname" {
  default = "mongodb://username:password@ad3a417b4b4d84d618e8dd8e6775fdc3-1076869512.eu-central-1.elb.amazonaws.com"
}

variable "mongo_secret" {
  
}

variable "vpc_id" {
  
}