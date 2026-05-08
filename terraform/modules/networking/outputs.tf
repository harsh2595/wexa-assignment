output "vpc_id" {
  description = "Default VPC ID used by StatusPulse."
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Default VPC subnet IDs."
  value       = data.aws_subnets.default.ids
}

output "public_subnet_id" {
  description = "Subnet selected for the StatusPulse EC2 instance."
  value       = data.aws_subnets.default.ids[0]
}

output "security_group_id" {
  description = "Security group ID for StatusPulse."
  value       = aws_security_group.statuspulse.id
}
