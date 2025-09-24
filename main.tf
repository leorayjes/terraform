module "web_server_dev" {
  source        = "./modules/web-server"
  project_name  = var.project_name
  environment   = "dev"
  instance_type = var.instance_type
}

module "web_server_prod" {
  source        = "./modules/web-server"
  project_name  = var.project_name
  environment   = "prod"
  instance_type = var.instance_type
}