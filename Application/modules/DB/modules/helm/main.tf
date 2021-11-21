provider "helm" {
  kubernetes {
    host = var.cluster_endpoint

    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.cluster_auth_token
  }
}

resource "helm_release" "kubernetes_efs_csi_driver" {
  name       = var.helm_chart_name
  chart      = var.helm_chart_release_name
  repository = var.helm_chart_repo
  version    = var.helm_chart_version

  set {
        name  = "serviceAccount.name"
        value = var.service_account_name
    }

    values = [
        yamlencode(var.settings)
    ] 
}
