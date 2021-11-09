output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "cluster_auth_token" {
  description = "Kubernetes cluster authentication token"
  value       = data.aws_eks_cluster_auth.cluster.token
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster ca certificate"
  value       = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

output "efs_example_fsid" {
  value = aws_efs_file_system.ba-efs.id
}