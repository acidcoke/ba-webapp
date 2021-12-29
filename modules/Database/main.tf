module "aws" {
  aws_region = var.aws_region
  source     = "./modules/aws"

  name_prefix = var.name_prefix
}

module "kubernetes" {
  aws_region = var.aws_region
  source     = "./modules/kubernetes"

  cluster_endpoint       = module.aws.cluster_endpoint
  cluster_auth_token     = module.aws.cluster_auth_token
  cluster_ca_certificate = module.aws.cluster_ca_certificate

  efs_id         = module.aws.efs_id
  mongodb_secret = module.aws.mongodb_secret

  name_prefix = var.name_prefix
}
