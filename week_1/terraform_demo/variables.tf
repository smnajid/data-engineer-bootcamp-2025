variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "learn-de-zoomcamp-2025"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "europe-west6"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "europe-west6-a"
}

variable "location" {
  description = "The location for GCS bucket and BigQuery dataset"
  type        = string
  default     = "EUROPE-WEST6"
}

variable "credentials_file" {
  description = "Path to the GCP credentials JSON file"
  type        = string
  default     = "../../keys/gcp_de_camp_2025_cred.json"
}

variable "bucket_name" {
  description = "Name of the GCS bucket for data lake"
  type        = string
  default     = "de-zoomcamp-2025-data-lake"
}

variable "bucket_lifecycle_age" {
  description = "Number of days after which objects are deleted"
  type        = number
  default     = 30
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
  default     = "de_zoomcamp_dataset"
}

variable "dataset_friendly_name" {
  description = "BigQuery dataset friendly name"
  type        = string
  default     = "DE Zoomcamp Dataset"
}

variable "dataset_description" {
  description = "BigQuery dataset description"
  type        = string
  default     = "Dataset for Data Engineering Zoomcamp 2025"
}

variable "table_expiration_ms" {
  description = "Default table expiration time in milliseconds"
  type        = number
  default     = 3600000 # 1 hour
}

variable "service_account_id" {
  description = "Service account ID for BigQuery operations"
  type        = string
  default     = "bigquery-service-account"
}

variable "service_account_display_name" {
  description = "Service account display name"
  type        = string
  default     = "BigQuery Service Account"
}

variable "environment" {
  description = "Environment label (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_label" {
  description = "Project label for resource organization"
  type        = string
  default     = "de-zoomcamp"
}


