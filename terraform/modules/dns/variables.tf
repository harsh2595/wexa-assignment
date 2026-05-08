variable "route53_zone_id" {
  description = "Optional existing Route 53 hosted zone ID."
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

variable "records_ip" {
  description = "IPv4 address used by the app and status Route 53 records."
  type        = string
}
