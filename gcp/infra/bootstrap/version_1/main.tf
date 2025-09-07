variable "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state"
  type        = string
}

resource "google_storage_bucket" "state" {
  name                        = var.state_bucket_name
  location                    = "EU" # use multi-region matching your org, adjust if needed
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "state_bucket" {
  value       = google_storage_bucket.state.name
  description = "Name of the created state bucket"
}


