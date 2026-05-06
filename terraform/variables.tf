variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for AWS resources."
  type        = string
  default     = "statuspulse"
}

variable "ami_id" {
  description = "Optional Ubuntu AMI override. Empty uses Canonical Ubuntu 22.04 from SSM."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type. t2.micro is commonly used for AWS Free Tier style demos."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name used for SSH access."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to connect to the custom SSH port. Prefer your own /32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_port" {
  description = "Custom SSH port to configure in sshd, UFW, and the security group."
  type        = number
  default     = 2222
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "swap_size_gb" {
  description = "Swap file size in GiB for low-memory instances."
  type        = number
  default     = 2
}

variable "deploy_user" {
  description = "Non-root user that will own and deploy StatusPulse."
  type        = string
  default     = "deploy"
}

variable "deploy_public_key" {
  description = "Optional SSH public key for the deploy user. If empty, cloud-init copies ubuntu's authorized_keys."
  type        = string
  default     = ""
  sensitive   = true
}

variable "repository_url" {
  description = "Public Git repository URL to clone into /opt/statuspulse. Leave empty to copy files manually."
  type        = string
  default     = ""
}

variable "write_app_env" {
  description = "Whether cloud-init should write /opt/statuspulse/.env. This stores values in Terraform state."
  type        = bool
  default     = false
}

variable "ghcr_image" {
  description = "GHCR image used by the production deploy script."
  type        = string
  default     = "ghcr.io/owner/statuspulse:latest"
}

variable "domain_name" {
  description = "Primary StatusPulse domain, for example statuspulse.example.com."
  type        = string
  default     = ""
}

variable "status_domain" {
  description = "Uptime Kuma status page domain. Empty becomes status.<domain_name>."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Optional existing Route 53 hosted zone ID. Leave empty when using DuckDNS, Cloudflare, sslip.io, or manual DNS."
  type        = string
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt registration."
  type        = string
  default     = "you@example.com"
}

variable "db_name" {
  description = "PostgreSQL database name for StatusPulse."
  type        = string
  default     = "statuspulse"
}

variable "db_user" {
  description = "PostgreSQL username for StatusPulse."
  type        = string
  default     = "statuspulse"
}

variable "db_password" {
  description = "PostgreSQL password. Used only when write_app_env is true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password. Used only when write_app_env is true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "alert_webhook_url" {
  description = "Optional webhook URL for health-monitor alerts. Used only when write_app_env is true."
  type        = string
  default     = ""
  sensitive   = true
}
