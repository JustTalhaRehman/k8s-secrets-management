output "role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = module.external_secrets_irsa.iam_role_arn
}

output "role_name" {
  description = "Name of the IAM role for External Secrets Operator"
  value       = module.external_secrets_irsa.iam_role_name
}
