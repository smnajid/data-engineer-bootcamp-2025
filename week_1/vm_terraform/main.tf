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

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall rule for SSH
resource "google_compute_firewall" "ssh" {
  name    = "${var.vm_name}-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# Firewall rule for PostgreSQL
resource "google_compute_firewall" "postgres" {
  name    = "${var.vm_name}-postgres"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["postgres"]
}

# Firewall rule for Jupyter Notebook
resource "google_compute_firewall" "jupyter" {
  name    = "${var.vm_name}-jupyter"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8888", "8080", "3000", "5000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jupyter"]
}

# Service Account for the VM
resource "google_service_account" "vm_service_account" {
  account_id   = var.vm_service_account_id
  display_name = var.vm_service_account_display_name
  description  = "Service account for DE Zoomcamp VM"
}

# IAM bindings for the VM service account
resource "google_project_iam_member" "vm_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

resource "google_project_iam_member" "vm_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

resource "google_project_iam_member" "vm_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Compute Engine Instance
resource "google_compute_instance" "vm_instance" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone

  tags = ["ssh", "postgres", "jupyter"]

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size
      type  = var.vm_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  labels = {
    environment = var.environment
    project     = var.project_label
    purpose     = "data-engineering"
  }

  # Allow stopping for updates
  allow_stopping_for_update = true
  
  # Control VM state
  desired_status = var.vm_desired_status
}
