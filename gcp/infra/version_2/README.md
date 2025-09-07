# GCP Infrastructure - Version 2 (Terraform + Ansible)

This infrastructure setup uses **Terraform** for cloud resources and **Ansible** for VM configuration management, following DevOps best practices.

## Architecture

- **Terraform**: Creates GCP infrastructure (APIs, Storage, BigQuery, VM)
- **Ansible**: Configures the VM with development tools and environments
- **Separation of Concerns**: Infrastructure vs. Configuration Management

## GCP Resources Created

- **Project Services**: Enables required APIs (Compute, Storage, BigQuery)
- **GCS Bucket**: Data lake bucket with versioning and retention policies
- **BigQuery Dataset**: Analytics dataset with configurable table expiration
- **Compute Engine VM**: Development VM with minimal startup script (Ansible-ready)

## Prerequisites

1. GCP project with billing enabled
2. Terraform >= 1.5 installed
3. Ansible >= 2.9 installed (or use the automated installer in deploy.sh)
4. Google Cloud credentials configured
5. State bucket `tf-state-learn-de-zoomcamp-2025` exists
6. SSH key pair for VM access

### Installing Ansible

**macOS (with Homebrew):**
```bash
brew install ansible
```

**macOS (with pip):**
```bash
pip3 install ansible
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install -y ansible
```

**Linux (CentOS/RHEL):**
```bash
sudo yum install -y ansible
```

**Note:** The `deploy.sh` script will automatically install Ansible if it's not found.

## Deployment Process

### Step 1: Deploy Infrastructure with Terraform

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Validate configuration**:

   ```bash
   terraform validate
   ```

3. **Plan deployment**:

   ```bash
   terraform plan -var-file=env.auto.tfvars
   ```

4. **Apply infrastructure**:

   ```bash
   terraform apply -auto-approve -var-file=env.auto.tfvars
   ```

5. **Get VM IP address**:

   ```bash
   terraform output vm_external_ip
   ```

### Step 2: Configure VM with Ansible

1. **Update inventory with VM IP**:

   ```bash
   # Edit ansible/inventory/hosts.yml and replace CHANGE_ME with the actual VM IP
   # For macOS:
   sed -i '' "s/CHANGE_ME/$(terraform output -raw vm_external_ip)/" ansible/inventory/hosts.yml
   # For Linux:
   # sed -i "s/CHANGE_ME/$(terraform output -raw vm_external_ip)/" ansible/inventory/hosts.yml
   ```

2. **Generate SSH key (if needed)**:

   ```bash
   ssh-keygen -t rsa -b 4096 -f ansible/keys/gcp_key -N ""
   ```

3. **Copy SSH key to VM**:

   ```bash
   ssh-copy-id -i ansible/keys/gcp_key.pub ansible@$(terraform output -raw vm_external_ip)
   ```

4. **Run Ansible playbook**:

   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts.yml playbooks/setup-dev-environment.yml
   ```

### Step 3: Verify Installation

1. **SSH into the VM**:

   ```bash
   ssh -i ansible/keys/gcp_key ansible@$(terraform output -raw vm_external_ip)
   ```

2. **Test installed tools**:

   ```bash
   docker --version
   conda --version
   gcloud --version
   ```

## Ansible Structure

```
ansible/
├── playbooks/
│   └── setup-dev-environment.yml    # Main playbook
├── roles/
│   ├── common-tools/                # Basic development tools
│   ├── docker/                      # Docker installation
│   ├── miniconda/                   # Python/Conda environment
│   └── gcloud-sdk/                  # Google Cloud SDK
├── inventory/
│   └── hosts.yml                    # VM inventory
├── group_vars/
│   └── all.yml                      # Global variables
└── ansible.cfg                      # Ansible configuration
```

## Automated Deployment Script

Create a deployment script for easier setup:

```bash
#!/bin/bash
# deploy.sh - Automated deployment script

set -e

echo "🚀 Starting deployment..."

# Step 1: Deploy infrastructure
echo "📦 Deploying infrastructure with Terraform..."
terraform init
terraform apply -auto-approve -var-file=env.auto.tfvars

# Step 2: Get VM IP
VM_IP=$(terraform output -raw vm_external_ip)
echo "🖥️  VM IP: $VM_IP"

# Step 3: Update Ansible inventory
echo "📝 Updating Ansible inventory..."
# macOS compatible sed command
sed -i '' "s/CHANGE_ME/$VM_IP/" ansible/inventory/hosts.yml

# Step 4: Generate SSH key if needed
if [ ! -f "ansible/keys/gcp_key" ]; then
    echo "🔑 Generating SSH key..."
    mkdir -p ansible/keys
    ssh-keygen -t rsa -b 4096 -f ansible/keys/gcp_key -N ""
fi

# Step 5: Copy SSH key to VM
echo "🔐 Copying SSH key to VM..."
ssh-copy-id -i ansible/keys/gcp_key.pub ansible@$VM_IP

# Step 6: Run Ansible playbook
echo "⚙️  Configuring VM with Ansible..."
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/setup-dev-environment.yml

echo "✅ Deployment completed successfully!"
echo "🔗 SSH to VM: ssh -i keys/gcp_key ansible@$VM_IP"
```

## Variables

Create `env.auto.tfvars` with the following variables:

```hcl
project_id                    = "learn-de-zoomcamp-2025"
region                       = "europe-west6"
zones                        = ["europe-west6-a"]
bucket_name                  = "mohamed-de-zoomcamp-2025-data-lake"
bucket_location              = "EUROPE-WEST6"
bucket_uniform_access        = true
bucket_versioning            = true
bucket_retention_days        = 30
dataset_id                   = "de_zoomcamp_dataset"
dataset_location             = "europe-west6"
dataset_table_expiration_ms  = 3600000
vm_name                      = "learn-de-zoomcamp-2025-vm"
vm_machine_type              = "e2-standard-2"
vm_zone                      = "europe-west6-a"
vm_boot_disk_size_gb         = 30
vm_boot_disk_type            = "pd-balanced"
vm_image_family              = "debian-12"
vm_image_project             = "debian-cloud"
prevent_destroy_critical     = true
```

## Safety Notes

- Critical resources (bucket, dataset, VM) have `prevent_destroy = true` by default
- State is stored in GCS backend for team collaboration
- All resources are tagged with environment labels
- VM includes comprehensive startup script for development environment

## Outputs

After successful deployment, the following outputs are available:

- `bucket_name`: GCS bucket name
- `bucket_url`: GCS bucket URL
- `dataset_id`: BigQuery dataset ID
- `vm_name`: VM instance name
- `vm_external_ip`: VM external IP address

## Cleanup

To destroy resources (use with caution):

```bash
terraform destroy -var-file=env.auto.tfvars
```

**Warning**: This will delete all resources including data. Ensure you have backups if needed.
