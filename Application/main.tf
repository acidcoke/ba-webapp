module "API" {
  source                   = "./modules/API"
  mongodb_ingress_hostname = module.DB.mongodb_ingress_hostname
  mongo_secret             = module.DB.mongo_secret
  vpc_id                   = module.DB.vpc_id

  private_subnet_ids = module.DB.private_subnet_ids

  name_prefix = var.name_prefix
}

module "Frontend" {
  source    = "./modules/Frontend"
  api_route = module.API.api_route

  name_prefix = var.name_prefix
}

module "DB" {
  source = "./modules/DB"

  name_prefix = var.name_prefix
}
