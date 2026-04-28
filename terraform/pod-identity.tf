module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-external-secrets-operator"

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.secrets_manager_prefix}*"
  ]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }
}
