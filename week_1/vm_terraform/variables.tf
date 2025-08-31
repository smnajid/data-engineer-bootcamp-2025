# Project Configuration
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

variable "credentials_file" {
  description = "Path to the GCP credentials JSON file"
  type        = string
  default     = "../../keys/gcp_de_camp_2025_cred.json"
}

# Network Configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "de-zoomcamp-network"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "de-zoomcamp-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# VM Configuration
variable "vm_name" {
  description = "Name of the Compute Engine VM"
  type        = string
  default     = "de-zoomcamp-vm"
}

variable "vm_machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-standard-4"  # 4 vCPUs, 16 GB RAM
}

variable "vm_image" {
  description = "Boot disk image for the VM"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "vm_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "vm_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

# SSH Configuration
variable "ssh_user" {
  description = "SSH username for VM access"
  type        = string
  default     = "de-user"
}

variable "ssh_pub_key_file" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Service Account Configuration
variable "vm_service_account_id" {
  description = "Service account ID for the VM"
  type        = string
  default     = "de-vm-service-account"
}

variable "vm_service_account_display_name" {
  description = "Service account display name for the VM"
  type        = string
  default     = "DE VM Service Account"
}

# Labels
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
