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

variable "efs_example_fsid" {
  type = string
}
