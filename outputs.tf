output "parameter_name" {
  description = "Full SSM parameter path"
  value       = aws_ssm_parameter.app_version.name
}

output "parameter_arn" {
  description = "ARN of the SSM parameter"
  value       = aws_ssm_parameter.app_version.arn
}
