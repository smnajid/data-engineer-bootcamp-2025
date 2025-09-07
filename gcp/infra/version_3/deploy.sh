#!/bin/bash
# deploy.sh - Automated deployment script for Terraform + Ansible

set -e

echo "🚀 Starting deployment..."

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "📦 Ansible not found. Installing Ansible..."
    
    # Detect OS and install Ansible
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install ansible
        else
            echo "❌ Homebrew not found. Please install Ansible manually:"
            echo "   brew install ansible"
            echo "   Or: pip3 install ansible"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y ansible
        elif command -v yum &> /dev/null; then
            sudo yum install -y ansible
        else
            echo "❌ Package manager not found. Please install Ansible manually:"
            echo "   pip3 install ansible"
            exit 1
        fi
    else
        echo "❌ Unsupported OS. Please install Ansible manually:"
        echo "   pip3 install ansible"
        exit 1
    fi
    
    echo "✅ Ansible installed successfully!"
fi

# Step 1: Deploy infrastructure
echo "📦 Deploying infrastructure with Terraform..."
terraform init
terraform apply -auto-approve -var-file=env.auto.tfvars

# Step 2: Get VM IP
VM_IP=$(terraform output -raw vm_external_ip)
echo "🖥️  VM IP: $VM_IP"

# Step 3: Update Ansible inventory
echo "📝 Updating Ansible inventory..."
# Cross-platform sed command (works on both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/CHANGE_ME/$VM_IP/" ansible/inventory/hosts.yml
else
    # Linux
    sed -i "s/CHANGE_ME/$VM_IP/" ansible/inventory/hosts.yml
fi

# Step 4: Generate SSH key if needed
if [ ! -f "ansible/keys/gcp_key" ]; then
    echo "🔑 Generating SSH key..."
    mkdir -p ansible/keys
    ssh-keygen -t rsa -b 4096 -f ansible/keys/gcp_key -N ""
fi

# Step 5: Set up SSH access
echo "🔐 Setting up SSH access..."

# Wait for VM to be fully ready
echo "⏳ Waiting for VM to be ready (60 seconds)..."
sleep 60

# Use gcloud to add SSH key to VM metadata
echo "🔧 Adding SSH key to VM metadata..."
gcloud compute instances add-metadata learn-de-zoomcamp-2025-vm \
    --zone=europe-west6-a \
    --metadata-from-file ssh-keys=<(echo "ansible:$(cat ansible/keys/gcp_key.pub)")

echo "⏳ Waiting for SSH key to be applied (30 seconds)..."
sleep 30

# Test SSH connection
echo "🧪 Testing SSH connection..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ansible/keys/gcp_key ansible@$VM_IP "echo 'SSH connection successful!'"; then
    echo "✅ SSH connection established!"
else
    echo "❌ SSH connection failed. Please check the VM status."
    echo "📋 Troubleshooting steps:"
    echo "   1. Check VM status: gcloud compute instances describe learn-de-zoomcamp-2025-vm --zone=europe-west6-a"
    echo "   2. Check VM logs: gcloud compute instances get-serial-port-output learn-de-zoomcamp-2025-vm --zone=europe-west6-a"
    echo "   3. Try manual SSH: ssh -o StrictHostKeyChecking=no ansible@$VM_IP"
    echo ""
    echo "🔄 Continuing with Ansible setup (you may need to run it manually)..."
fi

# Step 6: Run Ansible playbook
echo "⚙️  Configuring VM with Ansible..."
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/setup-dev-environment.yml

echo "✅ Deployment completed successfully!"
echo "🔗 SSH to VM: ssh -i keys/gcp_key ansible@$VM_IP"
