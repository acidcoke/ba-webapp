module "API" {
  source = "./modules/API"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix
  vpc_id      = module.DB.vpc_id

  mongodb_ingress_hostname = module.DB.mongodb_ingress_hostname
  mongodb_secret           = module.DB.mongodb_secret

}

module "Frontend" {
  source = "./modules/Frontend"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix

  api_route = module.API.api_route
}

module "DB" {
  source = "./modules/DB"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix
}
