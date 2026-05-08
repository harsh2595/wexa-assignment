data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_ec2_instance_types" "free_tier_x86" {
  count = var.instance_type == "" ? 1 : 0

  filter {
    name   = "free-tier-eligible"
    values = ["true"]
  }

  filter {
    name   = "processor-info.supported-architecture"
    values = ["x86_64"]
  }
}

locals {
  ami_id        = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.instance_type != "" ? var.instance_type : sort(data.aws_ec2_instance_types.free_tier_x86[0].instance_types)[0]
}

resource "aws_instance" "statuspulse" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
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
    status_domain     = var.status_domain
    letsencrypt_email = var.letsencrypt_email
    db_name           = var.db_name
    db_user           = var.db_user
    db_password       = var.db_password
    redis_password    = var.redis_password
    health_url        = var.health_url
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
