output "mongodb_ingress_hostname" {
  description = "Hostname for load-balancer ingress point"
  value       = kubernetes_service.mongodb.status[0].load_balancer[0].ingress[0].hostname
}
