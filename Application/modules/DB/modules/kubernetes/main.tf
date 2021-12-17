variable "region" {
  default     = "eu-central-1"
  description = "AWS region"
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  token                  = var.cluster_auth_token
  cluster_ca_certificate = var.cluster_ca_certificate
}

resource "kubernetes_stateful_set" "mongodb_stateful_set" {
  metadata {
    name = "mongodb-stateful-set"
  }

  spec {
    replicas = 1
    selector {
      match_labels = local.app_label
    }
    template {
      metadata {
        labels = local.app_label
      }
      spec {
        volume {
          name = kubernetes_persistent_volume.mongodb_persistent_volume.metadata.0.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mongodb_persistent_volume_claim.metadata.0.name
          }
        }
        container {
          name  = "mongodb"
          image = "mongo"
          port {
            container_port = 27017
          }
          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb_secret.metadata.0.name
                key  = "mongo-root-username"
              }
            }
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb_secret.metadata.0.name
                key  = "mongo-root-password"
              }
            }
          }
          volume_mount {
            name       = kubernetes_persistent_volume.mongodb_persistent_volume.metadata.0.name
            mount_path = "/data/db"
          }
        }
      }
    }
    service_name = kubernetes_service.mongodb_service.metadata.0.name
  }
}

resource "kubernetes_service" "mongodb_service" {
  metadata {
    name = "mongodb-service"
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 27017
      target_port = 27017
    }

    selector = local.app_label
    type     = "LoadBalancer"
  }
}

resource "kubernetes_secret" "mongodb_secret" {

  metadata {
    name = "mongodb-secret"
  }

  data = {
    mongo-root-password = local.mongo_creds["password"]
    mongo-root-username = local.mongo_creds["username"]
  }
}

resource "kubernetes_persistent_volume" "mongodb_persistent_volume" {
  metadata {
    name = "mongodb-pv"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "efs-sc"
    capacity = {
      storage = "2Gi"
    }
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = var.efs_example_fsid
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mongodb_persistent_volume_claim" {
  metadata {
    name = "mongodb-claim"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "efs-sc"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.mongodb_persistent_volume.metadata.0.name
  }
}

data "aws_secretsmanager_secret_version" "mongo_credentials" {
  secret_id = var.mongo_secret
}

locals {
  mongo_creds = jsondecode(
    data.aws_secretsmanager_secret_version.mongo_credentials.secret_string
  )

  app_label = {
    app = "mongodb"
  }
  csi_driver = "aws-efs-csi-driver"
}


provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.cluster_auth_token
  }
}


resource "helm_release" "kubernetes_efs_csi_driver" {
  name       = local.csi_driver
  chart      = local.csi_driver
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  version    = "1.2.4"
}
