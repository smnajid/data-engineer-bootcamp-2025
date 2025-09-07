# Enable required services
resource "google_project_service" "services" {
  for_each           = toset([
    "compute.googleapis.com",
    "storage-component.googleapis.com",
    "bigquery.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Storage bucket with enhanced configuration
resource "google_storage_bucket" "data_bucket" {
  name                        = var.bucket_name
  location                    = var.bucket_location
  uniform_bucket_level_access = var.bucket_uniform_access

  versioning {
    enabled = var.bucket_versioning
  }

  dynamic "retention_policy" {
    for_each = var.bucket_retention_days > 0 ? [1] : []
    content {
      retention_period = var.bucket_retention_days * 24 * 60 * 60
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.services]
}

# BigQuery dataset with enhanced configuration
resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = var.dataset_id
  location                   = var.dataset_location
  default_table_expiration_ms = var.dataset_table_expiration_ms

  labels = {
    env     = "dev"
    project = "de-zoomcamp"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.services]
}

# Compute Engine VM with minimal startup script for Ansible
resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.vm_zone

  boot_disk {
    initialize_params {
      image = "projects/${var.vm_image_project}/global/images/family/${var.vm_image_family}"
      size  = var.vm_boot_disk_size_gb
      type  = var.vm_boot_disk_type
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral external IP
    }
  }

  # Minimal startup script - just install Ansible and basic tools
  metadata_startup_script = var.vm_startup_script

  labels = {
    env     = "dev"
    project = "de-zoomcamp"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.services]
}
