output "mongodb_ingress_hostname" {
  value = module.DB.mongodb_ingress_hostname
  
  

 
}

output "mongo_secret" {
  value             = module.DB.mongo_secret
}

output "vpc_id" {
          value           = module.DB.vpc_id
}

output "private_subnet_ids" {
          value      = module.DB.private_subnet_ids
}