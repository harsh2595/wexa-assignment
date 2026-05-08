variable "project_name" {
  description = "Name prefix for networking resources."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to connect to the custom SSH port."
  type        = string
}

variable "ssh_port" {
  description = "Custom SSH port to allow in the security group."
  type        = number
}
