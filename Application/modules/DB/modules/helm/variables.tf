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

variable "helm_chart_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "Amazon EFS CSI Driver chart name."
}

variable "helm_chart_release_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "Amazon EFS CSI Driver release name."
}

variable "helm_chart_repo" {
  type        = string
  default     = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  description = "Amazon EFS CSI Driver repository name."
}

variable "helm_chart_version" {
  type        = string
  default     = "1.2.4"
  description = "Amazon EFS CSI Driver chart version."
}

variable "service_account_name" {
  type        = string
  default     = "aws-efs-csi-driver"
  description = "Amazon EFS CSI Driver service account name."
}

variable "settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/kubernetes-sigs/aws-efs-csi-driver."
}
