module "API" {
  source = "./modules/API"
}

module "Frontend" {
  source = "./modules/Frontend"

  base_url = module.API.base_url
}