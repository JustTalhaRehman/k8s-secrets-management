# IAM Role for Service Accounts (IRSA) module for External Secrets Operator
# This creates an IAM role that can be assumed by the External Secrets Operator
# service account to access AWS Secrets Manager
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks?ref=v5.39.0"
  version = "~> 5.0"

  # Role name based on cluster name
  role_name = "${var.cluster_name}-external-secrets-operator"

  # Attach External Secrets Operator policy for Secrets Manager access
  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.secrets_manager_prefix}*"
  ]

  # OIDC provider configuration for IRSA
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }
}
