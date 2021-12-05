output "mongodb_ingress_hostname" {
  description = "Hostname for load-balancer ingress point"
  value       = module.kubernetes.mongodb_ingress_hostname
}

output "mongo_secret" {
  value = module.aws.mongo_secret
}

output "vpc_id" {
  value = module.aws.vpc_id
}

output "private_subnet_ids" {
  value = module.aws.private_subnet_ids
}