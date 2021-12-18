variable "aws_region" {
  default     = "eu-central-1"
  description = "AWS region"
}

variable "cluster_endpoint" {
  description = "host for a kubernetes provider"
  type        = string
}

variable "cluster_auth_token" {
  description = "Kubernetes cluster authentication token"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Kubernetes cluster ca certificate"
  type        = string
}

variable "efs_id" {
  type = string
}

variable "mongodb_secret" {

}

variable "name_prefix" {
  type = string
}
