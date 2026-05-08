output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.statuspulse.id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = aws_instance.statuspulse.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance."
  value       = aws_instance.statuspulse.public_dns
}

output "instance_type" {
  description = "EC2 instance type selected for StatusPulse."
  value       = aws_instance.statuspulse.instance_type
}
