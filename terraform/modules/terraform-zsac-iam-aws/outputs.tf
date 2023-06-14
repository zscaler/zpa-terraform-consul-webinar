output "iam_instance_profile_id" {
  description = "App Connector IAM Instance Profile"
  value       = aws_iam_instance_profile.instance_profile[*].name
}

output "iam_instance_profile_arn" {
  description = "App Connector IAM Instance Profile ARN"
  value       = aws_iam_instance_profile.instance_profile[*].arn
}
