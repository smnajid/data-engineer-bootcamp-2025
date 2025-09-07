output "bucket_name" {
  value       = google_storage_bucket.data_bucket.name
  description = "Created GCS bucket name"
}

output "dataset_id" {
  value       = google_bigquery_dataset.dataset.dataset_id
  description = "Created BigQuery dataset id"
}

output "vm_self_link" {
  value       = google_compute_instance.vm.self_link
  description = "Self link of the Compute Engine VM"
}


