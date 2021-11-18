output "mongodb_ingress_hostname" {
  description = "Hostname for load-balancer ingress point"
  value       = module.kubernetes.mongodb_ingress_hostname
}

output "mongo_secret" {
  value = module.aws.mongo_secret
}