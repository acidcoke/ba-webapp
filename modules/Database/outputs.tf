output "mongodb_ingress_hostname" {
  description = "Hostname for load-balancer ingress point"
  value       = module.kubernetes.mongodb_ingress_hostname
}

output "mongodb_secret" {
  value = module.aws.mongodb_secret
}

output "vpc_id" {
  value = module.aws.vpc_id
}
