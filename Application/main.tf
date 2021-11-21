module "API" {
  source                   = "./modules/API"
  mongodb_ingress_hostname = module.DB.mongodb_ingress_hostname
  mongo_secret             = module.DB.mongo_secret
  vpc_id                   = module.DB.vpc_id
}

module "Frontend" {
  source    = "./modules/Frontend"
  api_route = module.API.api_route
}

module "DB" {
  source = "./modules/DB"
}
