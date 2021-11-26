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
    labels = {
      app = "mongodb"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mongodb"
      }
    }
    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }
      spec {
        volume {
          name = "mongodb-pv"
          persistent_volume_claim {
            claim_name = "mongodb-claim"
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
                name = "mongodb-secret"
                key  = "mongo-root-username"
              }
            }
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "mongodb-secret"
                key  = "mongo-root-password"
              }
            }
          }
          volume_mount {
            name       = "mongodb-pv"
            mount_path = "/data/mongodb"
          }
        }
      }
    }
    service_name = "mongodb-service"
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
      target_port = "27017"
    }

    selector = {
      app = "mongodb"
    }
    type = "LoadBalancer"
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

resource "kubernetes_persistent_volume" "storage" {
  metadata {
    name = "mongodb-pv"
  }
  spec {
    storage_class_name               = "efs-sc"
    persistent_volume_reclaim_policy = "Retain"
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = var.efs_example_fsid
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "storage" {

  metadata {
    name = "mongodb-claim"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.storage.metadata.0.name
  }
}

data "aws_secretsmanager_secret_version" "mongo_credentials" {
  secret_id = data.aws_secretsmanager_secret.mongo_secret.arn
}

locals {
  mongo_creds = jsondecode(
    data.aws_secretsmanager_secret_version.mongo_credentials.secret_string
  )
}


provider "helm" {
  kubernetes {
    host = var.cluster_endpoint

    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.cluster_auth_token
  }
}

resource "helm_release" "kubernetes_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  version    = "1.2.4"

  set {
    name  = "serviceAccount.name"
    value = "aws-efs-csi-driver"
  }
}
