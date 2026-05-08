output "app_fqdn" {
  description = "Created app DNS record, when Route 53 is enabled."
  value       = try(aws_route53_record.app[0].fqdn, "")
}

output "status_fqdn" {
  description = "Created status DNS record, when Route 53 is enabled."
  value       = try(aws_route53_record.status[0].fqdn, "")
}
