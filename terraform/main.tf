terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  status_domain = var.status_domain != "" ? var.status_domain : "status.${var.domain_name}"
  health_url    = var.domain_name != "" ? "https://${var.domain_name}/health" : ""
}

module "networking" {
  source = "./modules/networking"

  project_name     = var.project_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
  ssh_port         = var.ssh_port
}

module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
  subnet_id          = module.networking.public_subnet_id
  security_group_ids = [module.networking.security_group_id]
  root_volume_size   = var.root_volume_size

  deploy_user       = var.deploy_user
  deploy_public_key = var.deploy_public_key
  ssh_port          = var.ssh_port
  swap_size_gb      = var.swap_size_gb

  repository_url    = var.repository_url
  write_app_env     = var.write_app_env
  ghcr_image        = var.ghcr_image
  domain_name       = var.domain_name
  status_domain     = local.status_domain
  letsencrypt_email = var.letsencrypt_email
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
  redis_password    = var.redis_password
  health_url        = local.health_url
  alert_webhook_url = var.alert_webhook_url
}

module "dns" {
  source = "./modules/dns"

  route53_zone_id = var.route53_zone_id
  domain_name     = var.domain_name
  status_domain   = local.status_domain
  records_ip      = module.compute.public_ip
}
