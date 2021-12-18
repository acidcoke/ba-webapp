module "aws" {
  source = "./modules/aws"

  name_prefix = var.name_prefix
}

module "kubernetes" {
  source = "./modules/kubernetes"

  cluster_endpoint       = module.aws.cluster_endpoint
  cluster_auth_token     = module.aws.cluster_auth_token
  cluster_ca_certificate = module.aws.cluster_ca_certificate

  efs_example_fsid = module.aws.efs_example_fsid
  mongo_secret     = module.aws.mongo_secret

  name_prefix = var.name_prefix
}
