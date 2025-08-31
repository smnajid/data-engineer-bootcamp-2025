#!/bin/bash

# Startup script for DE Zoomcamp VM
# This script installs miniconda, PostgreSQL, and other useful tools

set -e  # Exit on any error

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tree \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group (will be done for the SSH user later)
groupadd -f docker

# Install PostgreSQL
apt-get install -y postgresql postgresql-contrib postgresql-client

# Configure PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Set up PostgreSQL user and database
sudo -u postgres psql -c "CREATE USER de_user WITH PASSWORD 'de_password';"
sudo -u postgres psql -c "CREATE DATABASE de_zoomcamp OWNER de_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE de_zoomcamp TO de_user;"

# Configure PostgreSQL for remote connections
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/*/main/pg_hba.conf
systemctl restart postgresql

# Install Miniconda
cd /tmp
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh

# Install miniconda for the default user (will be moved to user home later)
bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3

# Make conda available system-wide
ln -sf /opt/miniconda3/bin/conda /usr/local/bin/conda
ln -sf /opt/miniconda3/bin/python /usr/local/bin/python3-conda

# Initialize conda for bash
/opt/miniconda3/bin/conda init bash

# Install Python packages commonly used in data engineering
/opt/miniconda3/bin/conda install -y \
    pandas \
    numpy \
    jupyter \
    matplotlib \
    seaborn \
    sqlalchemy \
    psycopg2 \
    requests \
    boto3

# Install additional Python packages via pip
/opt/miniconda3/bin/pip install \
    google-cloud-storage \
    google-cloud-bigquery \
    apache-airflow \
    dbt-core \
    dbt-postgres \
    dbt-bigquery

# Install Terraform (in case needed on VM)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform

# Install Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update
apt-get install -y google-cloud-cli

# Create a setup script for new users
cat > /etc/profile.d/de-setup.sh << 'EOF'
# Data Engineering environment setup
export PATH="/opt/miniconda3/bin:$PATH"

# Add user to docker group if not already
if ! groups | grep -q docker; then
    sudo usermod -aG docker $USER
    echo "Added $USER to docker group. Please log out and back in for changes to take effect."
fi

# Initialize conda if not already done for this user
if [ ! -f ~/.condarc ]; then
    conda init bash
    echo "Conda initialized for $USER. Please restart your shell or run 'source ~/.bashrc'"
fi

# Show useful information
echo "=== Data Engineering VM Ready ==="
echo "- Python/Conda: $(python --version 2>/dev/null || echo 'Not in PATH')"
echo "- PostgreSQL: Running on port 5432"
echo "- Docker: $(docker --version 2>/dev/null || echo 'Not available')"
echo "- Terraform: $(terraform version 2>/dev/null | head -1 || echo 'Not available')"
echo "================================="
EOF

# Set permissions
chmod +x /etc/profile.d/de-setup.sh

# Create a welcome message
cat > /etc/motd << 'EOF'
*************************************************
*        Data Engineering Zoomcamp VM          *
*************************************************
*                                               *
* Pre-installed tools:                          *
* - Miniconda with Python data science stack   *
* - PostgreSQL (user: de_user, db: de_zoomcamp)*
* - Docker & Docker Compose                    *
* - Google Cloud SDK                           *
* - Terraform                                  *
*                                               *
* Connect with VS Code using Remote-SSH        *
* extension for the best development experience*
*                                               *
*************************************************
EOF

# Clean up
rm -f /tmp/Miniconda3-latest-Linux-x86_64.sh
apt-get autoremove -y
apt-get autoclean

echo "VM setup completed successfully!"
