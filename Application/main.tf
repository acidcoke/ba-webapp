module "API" {
  aws_region               = var.aws_region
  source                   = "./modules/API"
  mongodb_ingress_hostname = module.DB.mongodb_ingress_hostname
  mongodb_secret           = module.DB.mongodb_secret
  vpc_id                   = module.DB.vpc_id

  private_subnet_ids = module.DB.private_subnet_ids

  name_prefix = var.name_prefix
}

module "Frontend" {
  aws_region = var.aws_region
  source     = "./modules/Frontend"
  api_route  = module.API.api_route

  name_prefix = var.name_prefix
}

module "DB" {
  aws_region = var.aws_region
  source     = "./modules/DB"

  name_prefix = var.name_prefix
}
