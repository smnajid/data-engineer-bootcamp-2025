<!-- markdownlint-disable MD041 MD032 MD012 -->
### Infrastructure - Version 1

Applies a minimal stack: GCS bucket, BigQuery dataset, and a VM with a startup script.

Prereqs:

- Terraform >= 1.5
- GCP project access, `gcloud auth application-default login` or GOOGLE_APPLICATION_CREDENTIALS

Steps:

1. terraform init
2. terraform validate
3. terraform plan -var-file=env.auto.tfvars
4. terraform apply -auto-approve -var-file=env.auto.tfvars

