# VM Instance Information
output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm_instance.name
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}

output "vm_zone" {
  description = "Zone where the VM is located"
  value       = google_compute_instance.vm_instance.zone
}

output "vm_machine_type" {
  description = "Machine type of the VM"
  value       = google_compute_instance.vm_instance.machine_type
}

# Connection Information
output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_connection_with_key" {
  description = "SSH connection command with key file"
  value       = "ssh -i ${replace(var.ssh_pub_key_file, ".pub", "")} ${var.ssh_user}@${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}

# Service URLs
output "jupyter_lab_url" {
  description = "Jupyter Lab URL"
  value       = "http://${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}:8888"
}

output "vscode_server_url" {
  description = "VS Code Server URL (after starting code-server)"
  value       = "http://${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}:8080"
}

# Database Connection
output "postgres_connection" {
  description = "PostgreSQL connection string"
  value       = "postgresql://de_user:de_password@${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}:5432/de_zoomcamp"
}

output "postgres_host" {
  description = "PostgreSQL host"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

# Network Information
output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

# Service Account Information
output "vm_service_account_email" {
  description = "Email of the VM service account"
  value       = google_service_account.vm_service_account.email
}

# VS Code Remote SSH Configuration
output "vscode_remote_ssh_config" {
  description = "VS Code Remote SSH configuration"
  value = <<EOT
Host de-zoomcamp-vm
    HostName ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}
    User ${var.ssh_user}
    IdentityFile ${replace(var.ssh_pub_key_file, ".pub", "")}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOT
}

# Setup Instructions
output "setup_instructions" {
  description = "Setup instructions for connecting to the VM"
  value = <<EOT

=== DE Zoomcamp VM Setup Complete ===

1. SSH Connection:
   ${local.ssh_command}

2. VS Code Remote SSH:
   - Install "Remote - SSH" extension in VS Code
   - Add this to your SSH config (~/.ssh/config):
   ${local.vscode_config}

3. Jupyter Lab:
   Open: ${local.jupyter_url}

4. PostgreSQL:
   Host: ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}
   Port: 5432
   Database: de_zoomcamp
   User: de_user
   Password: de_password

5. VS Code Server (if preferred over Remote SSH):
   SSH to VM and run: code-server --bind-addr 0.0.0.0:8080
   Then open: ${local.vscode_server_url}

========================================
EOT
}

# Local values for cleaner output
locals {
  vm_ip = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
  ssh_command = "ssh ${var.ssh_user}@${local.vm_ip}"
  jupyter_url = "http://${local.vm_ip}:8888"
  vscode_server_url = "http://${local.vm_ip}:8080"
  vscode_config = <<EOT
Host de-zoomcamp-vm
    HostName ${local.vm_ip}
    User ${var.ssh_user}
    IdentityFile ${replace(var.ssh_pub_key_file, ".pub", "")}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOT
}
