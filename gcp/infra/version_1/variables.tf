variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
}

variable "zone" {
  description = "Default zone"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket to create"
  type        = string
}

variable "bucket_location" {
  description = "Location/region for the bucket"
  type        = string
}

variable "bucket_retention_days" {
  description = "Retention policy in days"
  type        = number
  default     = 0
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "dataset_location" {
  description = "BigQuery dataset location"
  type        = string
}

variable "dataset_table_expiration_ms" {
  description = "Default table expiration in ms for the dataset"
  type        = number
  default     = null
}

variable "vm_name" {
  description = "Compute Engine instance name"
  type        = string
}

variable "vm_machine_type" {
  description = "Compute Engine machine type"
  type        = string
}

variable "vm_zone" {
  description = "Zone for the VM"
  type        = string
}

variable "vm_boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "vm_boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "vm_image_family" {
  description = "Image family"
  type        = string
}

variable "vm_image_project" {
  description = "Image project"
  type        = string
}

variable "vm_startup_script" {
  description = "Startup script content for the VM"
  type        = string
  default     = ""
}


