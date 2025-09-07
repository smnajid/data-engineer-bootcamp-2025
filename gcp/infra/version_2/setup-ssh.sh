#!/bin/bash
# setup-ssh.sh - Manual SSH setup script

set -e

echo "🔧 Manual SSH Setup Script"
echo "=========================="

# Get VM IP from Terraform
VM_IP=$(terraform output -raw vm_external_ip)
echo "🖥️  VM IP: $VM_IP"

# Check if SSH key exists
if [ ! -f "ansible/keys/gcp_key" ]; then
    echo "🔑 Generating SSH key..."
    mkdir -p ansible/keys
    ssh-keygen -t rsa -b 4096 -f ansible/keys/gcp_key -N ""
fi

echo "📋 SSH Setup Options:"
echo "1. Use gcloud to add SSH key to VM metadata"
echo "2. Manual SSH connection and key setup"
echo "3. Exit"
echo ""

read -p "Choose option (1-3): " choice

case $choice in
    1)
        echo "🔧 Adding SSH key to VM metadata..."
        gcloud compute instances add-metadata learn-de-zoomcamp-2025-vm \
            --zone=europe-west6-a \
            --metadata-from-file ssh-keys=<(echo "ansible:$(cat ansible/keys/gcp_key.pub)")
        
        echo "⏳ Waiting for SSH key to be applied..."
        sleep 30
        
        echo "🧪 Testing SSH connection..."
        if ssh -o StrictHostKeyChecking=no -i ansible/keys/gcp_key ansible@$VM_IP "echo 'SSH connection successful!'"; then
            echo "✅ SSH connection established!"
        else
            echo "❌ SSH connection failed. Try option 2."
        fi
        ;;
    2)
        echo "📋 Manual SSH setup instructions:"
        echo "1. SSH to VM: ssh -o StrictHostKeyChecking=no ansible@$VM_IP"
        echo "2. Create .ssh directory: mkdir -p ~/.ssh"
        echo "3. Copy your public key:"
        echo "   cat << 'EOF' >> ~/.ssh/authorized_keys"
        cat ansible/keys/gcp_key.pub
        echo "   EOF"
        echo "4. Set permissions: chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
        echo "5. Test connection: ssh -i ansible/keys/gcp_key ansible@$VM_IP"
        ;;
    3)
        echo "👋 Exiting..."
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac
