<!-- markdownlint-disable MD041 MD032 MD012 -->
### Bootstrap - Version 1

Creates the Terraform state bucket. Run this before the main stack.

Steps:

1. export GOOGLE_APPLICATION_CREDENTIALS=...</br>
2. terraform init
3. terraform apply -auto-approve -var "project_id=learn-de-zoomcamp-2025" -var "region=europe-west6" -var "state_bucket_name=tf-state-learn-de-zoomcamp-2025"


