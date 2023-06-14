output "public_ip" {
  description = "Instance Public IP"
  value       = aws_instance.consul_server.public_ip
}

output "public_dns" {
  description = "Instance Public DNS"
  value       = aws_instance.consul_server.public_dns
}

output "private_ip" {
  description = "Instance Private IP Address"
  value       = aws_instance.consul_server.private_ip
}

output "availability_zone" {
  description = "Instance Availability Zone"
  value       = aws_instance.consul_server.availability_zone
}

output "id" {
  description = "Instance ID"
  value       = aws_instance.consul_server.id
}