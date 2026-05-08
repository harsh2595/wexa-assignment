variable "project_name" {
  description = "Name tag for the EC2 instance."
  type        = string
}

variable "ami_id" {
  description = "Optional Ubuntu AMI override. Empty uses Canonical Ubuntu 22.04 from SSM."
  type        = string
}

variable "instance_type" {
  description = "Optional EC2 instance type override. Empty auto-selects a Free Tier eligible x86_64 type."
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name used for SSH access."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched."
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to the EC2 instance."
  type        = list(string)
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
}

variable "deploy_user" {
  description = "Non-root user that will own and deploy StatusPulse."
  type        = string
}

variable "deploy_public_key" {
  description = "Optional SSH public key for the deploy user."
  type        = string
  sensitive   = true
}

variable "ssh_port" {
  description = "Custom SSH port configured in sshd and UFW."
  type        = number
}

variable "swap_size_gb" {
  description = "Swap file size in GiB for low-memory instances."
  type        = number
}

variable "repository_url" {
  description = "Public Git repository URL to clone into /opt/statuspulse."
  type        = string
}

variable "write_app_env" {
  description = "Whether cloud-init should write /opt/statuspulse/.env."
  type        = bool
}

variable "ghcr_image" {
  description = "GHCR image used by the production deploy script."
  type        = string
}

variable "domain_name" {
  description = "Primary StatusPulse domain."
  type        = string
}

variable "status_domain" {
  description = "Uptime Kuma status page domain."
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt registration."
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name for StatusPulse."
  type        = string
}

variable "db_user" {
  description = "PostgreSQL username for StatusPulse."
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password. Used only when write_app_env is true."
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password. Used only when write_app_env is true."
  type        = string
  sensitive   = true
}

variable "health_url" {
  description = "External StatusPulse /health URL used by scripts."
  type        = string
}

variable "alert_webhook_url" {
  description = "Optional webhook URL for health-monitor alerts."
  type        = string
  sensitive   = true
}
