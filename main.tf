module "network" {
  source            = "./modules/network"
  availability_zone = var.availability_zone
}

module "compute" {
  source           = "./modules/compute"
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  instance_name    = var.instance_name
}