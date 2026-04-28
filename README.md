# Kubernetes Secrets Management with External Secrets Operator

A zero-secrets-in-git setup for Kubernetes. All secrets live in AWS Secrets Manager. The External Secrets Operator pulls them into Kubernetes Secrets on a schedule — no manual `kubectl create secret`, no secrets in YAML files, no secrets in Git.

## Features

- **Zero secrets in Git**: No sensitive data stored in version control
- **Automated sync**: External Secrets Operator polls AWS Secrets Manager on configurable schedule
- **IRSA authentication**: Secure IAM role for service accounts, no static credentials
- **GitOps ready**: Helm charts compatible with ArgoCD and other GitOps tools
- **Namespace isolation**: Support for both cluster-wide and namespace-scoped secret stores

## How it works

```
AWS Secrets Manager
        │
        │  (ESO polls every 1h)
        ▼
ExternalSecret (K8s CRD)
        │
        │  (ESO creates/updates)
        ▼
Kubernetes Secret
        │
        ▼
   Your Pod
```

The `ClusterSecretStore` authenticates to AWS via IRSA (IAM Role for Service Accounts) — no static credentials needed.

## Structure

```
k8s-secrets-management/
├── terraform/
│   ├── main.tf           # Provider config + state backend
│   ├── variables.tf
│   ├── outputs.tf
│   └── pod-identity.tf   # IRSA role for ESO → AWS Secrets Manager
├── helm/
│   └── external-secrets-operator/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── cluster-secret-store.yaml
│           └── pod-identity-annotation.yaml
└── examples/
    ├── external-secret.yaml   # How to define a secret sync
    └── secret-store.yaml      # Namespace-scoped store example
```

## Structure

```
k8s-secrets-management/
├── terraform/
│   ├── main.tf           # Provider config + state backend
│   ├── variables.tf
│   ├── outputs.tf
│   └── pod-identity.tf   # IRSA role for ESO → AWS Secrets Manager
├── helm/
│   └── external-secrets-operator/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── cluster-secret-store.yaml
│           └── pod-identity-annotation.yaml
└── examples/
    ├── external-secret.yaml   # How to define a secret sync
    └── secret-store.yaml      # Namespace-scoped store example
```

## Prerequisites

- EKS cluster with OIDC provider enabled
- Terraform >= 1.5.0
- `helm` v3+
- AWS credentials

## Quick Start

### 1. Create the IRSA role

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Fill in your cluster name, OIDC ARN, and AWS region
terraform init
terraform apply
```

### 2. Install External Secrets Operator

Update `helm/external-secrets-operator/values.yaml` with the IAM role ARN from step 1:

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/my-cluster-external-secrets"
```

Then install via Helm:

```bash
helm install external-secrets \
  helm/external-secrets-operator \
  --namespace external-secrets \
  --create-namespace
```

Or let ArgoCD manage it — point an Application at `helm/external-secrets-operator/`.

### 3. Define your secrets

```bash
# Store a secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name myapp/database/password \
  --secret-string '{"password":"supersecret"}'

# Apply the ExternalSecret to sync it to K8s
kubectl apply -f examples/external-secret.yaml
```

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Fill in your cluster name, OIDC ARN, and AWS region
terraform init
terraform apply
```

### 2. Install External Secrets Operator

Update `helm/external-secrets-operator/values.yaml` with the IAM role ARN from step 1:

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/my-cluster-external-secrets"
```

Then install via Helm:

```bash
helm install external-secrets \
  helm/external-secrets-operator \
  --namespace external-secrets \
  --create-namespace
```

Or let ArgoCD manage it — point an Application at `helm/external-secrets-operator/`.

### 3. Define your secrets

```bash
# Store a secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name myapp/database/password \
  --secret-string '{"password":"supersecret"}'

# Apply the ExternalSecret to sync it to K8s
kubectl apply -f examples/external-secret.yaml
```

## Storing secrets

All secrets follow the naming convention `<app>/<component>/<key>`:

```
myapp/database/password
myapp/api/keys
platform/grafana/admin-password
```

This makes IAM policies simple — scope access by prefix.

## Refresh interval

Secrets sync every 1 hour by default. Change in your ExternalSecret:

```yaml
spec:
  refreshInterval: 30m
```
