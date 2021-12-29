module "API" {
  source = "./modules/API"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix
  vpc_id      = module.Database.vpc_id

  mongodb_ingress_hostname = module.Database.mongodb_ingress_hostname
  mongodb_secret           = module.Database.mongodb_secret

  website_bucket_name = var.website_bucket_name
}

module "Frontend" {
  source = "./modules/Frontend"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix

  api_route = module.API.api_route

  website_bucket_name = var.website_bucket_name
}

module "Database" {
  source = "./modules/Database"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix
}
