output "mongodb_secret" {
  value = aws_secretsmanager_secret.mongodb.arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_auth_token" {
  description = "Kubernetes cluster authentication token"
  value       = data.aws_eks_cluster_auth.this.token
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster ca certificate"
  value       = base64decode(module.eks.cluster_certificate_authority_data)
}

output "efs_id" {
  value = aws_efs_file_system.this.id
}
