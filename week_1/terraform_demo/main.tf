terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Google Cloud Storage bucket
resource "google_storage_bucket" "data_lake_bucket" {
  name          = var.bucket_name
  location      = var.location
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.bucket_lifecycle_age
    }
    action {
      type = "Delete"
    }
  }
}

# BigQuery dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_friendly_name
  description                 = var.dataset_description
  location                    = lower(var.location)
  default_table_expiration_ms = var.table_expiration_ms

  labels = {
    env     = var.environment
    project = var.project_label
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.bq_sa.email
  }
}

# Service account for BigQuery
resource "google_service_account" "bq_sa" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for BigQuery operations"
}

# IAM binding for BigQuery service account
resource "google_project_iam_member" "bq_sa_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.bq_sa.email}"
}

# Output the bucket name for reference
output "bucket_name" {
  value = google_storage_bucket.data_lake_bucket.name
}

# Output the BigQuery dataset ID
output "bigquery_dataset_id" {
  value = google_bigquery_dataset.dataset.dataset_id
}

# Output the BigQuery dataset location
output "bigquery_dataset_location" {
  value = google_bigquery_dataset.dataset.location
}
