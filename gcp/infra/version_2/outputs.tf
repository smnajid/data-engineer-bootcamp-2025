output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The default region"
  value       = var.region
}

output "bucket_name" {
  description = "The name of the created GCS bucket"
  value       = google_storage_bucket.data_bucket.name
}

output "bucket_url" {
  description = "The URL of the created GCS bucket"
  value       = google_storage_bucket.data_bucket.url
}

output "dataset_id" {
  description = "The ID of the created BigQuery dataset"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "dataset_location" {
  description = "The location of the created BigQuery dataset"
  value       = google_bigquery_dataset.dataset.location
}

output "vm_name" {
  description = "The name of the created VM instance"
  value       = google_compute_instance.vm.name
}

output "vm_zone" {
  description = "The zone of the created VM instance"
  value       = google_compute_instance.vm.zone
}

output "vm_internal_ip" {
  description = "The internal IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "vm_external_ip" {
  description = "The external IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}
