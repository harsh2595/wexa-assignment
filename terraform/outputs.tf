output "instance_public_ip" {
  description = "Public IPv4 address of the StatusPulse EC2 instance."
  value       = aws_instance.statuspulse.public_ip
}

output "ssh_command" {
  description = "SSH command using the hardened custom port."
  value       = "ssh -p ${var.ssh_port} ${var.deploy_user}@${aws_instance.statuspulse.public_ip}"
}

output "app_url" {
  description = "Primary StatusPulse URL when a domain was provided."
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_instance.statuspulse.public_ip}.sslip.io"
}

output "status_url" {
  description = "Uptime Kuma status page URL when a domain was provided."
  value       = var.domain_name != "" ? "https://${local.status_domain}" : "Set a DNS name or use sslip.io manually"
}
