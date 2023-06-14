output "availability_zone" {
  description = "Instance Availability Zone"
  value       = aws_autoscaling_group.web_asg.availability_zones
}
