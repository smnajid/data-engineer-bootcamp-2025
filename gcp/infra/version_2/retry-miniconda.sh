#!/bin/bash
# retry-miniconda.sh - Retry just the miniconda role

set -e

echo "🔄 Retrying Miniconda installation..."

cd ansible

# Get VM IP from Terraform
VM_IP=$(cd .. && terraform output -raw vm_external_ip)
echo "🖥️  VM IP: $VM_IP"

# Update inventory with current VM IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/ansible_host: .*/ansible_host: $VM_IP/" inventory/hosts.yml
else
    sed -i "s/ansible_host: .*/ansible_host: $VM_IP/" inventory/hosts.yml
fi

echo "⚙️  Running Miniconda role only..."
ansible-playbook -i inventory/hosts.yml playbooks/setup-dev-environment.yml --tags "conda,data-science,python"

echo "✅ Miniconda installation completed!"
