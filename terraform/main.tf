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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

locals {
  ami_id        = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.ubuntu_ami.value
  status_domain = var.status_domain != "" ? var.status_domain : "status.${var.domain_name}"
}

resource "aws_security_group" "statuspulse" {
  name        = "${var.project_name}-sg"
  description = "StatusPulse public HTTP/HTTPS and hardened SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Custom SSH"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

resource "aws_instance" "statuspulse" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.statuspulse.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
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
    health_url        = var.domain_name != "" ? "https://${var.domain_name}/health" : ""
    alert_webhook_url = var.alert_webhook_url
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

resource "aws_route53_record" "app" {
  count   = var.route53_zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.statuspulse.public_ip]
}

resource "aws_route53_record" "status" {
  count   = var.route53_zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = local.status_domain
  type    = "A"
  ttl     = 60
  records = [aws_instance.statuspulse.public_ip]
}
