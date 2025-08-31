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
    lsb-release \
    build-essential

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add docker group
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

# Install miniconda system-wide
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

# Install VSCode Server for remote development
curl -fsSL https://code-server.dev/install.sh | sh

# Create directories for data engineering work
mkdir -p /home/de-user/workspace
mkdir -p /home/de-user/data
mkdir -p /home/de-user/projects

# Set up user environment script
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
echo "- Python/Conda: $(/opt/miniconda3/bin/python --version)"
echo "- PostgreSQL: Running on port 5432"
echo "- Docker: $(docker --version)"
echo "- Terraform: $(terraform version | head -1)"
echo "- Google Cloud SDK: $(gcloud version --format='value(Google Cloud SDK)')"
echo ""
echo "PostgreSQL Connection:"
echo "  Host: localhost (or VM external IP)"
echo "  Port: 5432"
echo "  Database: de_zoomcamp"
echo "  User: de_user"
echo "  Password: de_password"
echo ""
echo "VS Code Server: code-server --bind-addr 0.0.0.0:8080"
echo "Jupyter Lab: jupyter lab --ip=0.0.0.0 --port=8888 --allow-root"
echo "================================="
EOF

# Set permissions
chmod +x /etc/profile.d/de-setup.sh

# Create Jupyter config
mkdir -p /etc/jupyter
cat > /etc/jupyter/jupyter_lab_config.py << 'EOF'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.token = ''
c.ServerApp.password = ''
EOF

# Create systemd service for Jupyter Lab
cat > /etc/systemd/system/jupyter.service << 'EOF'
[Unit]
Description=Jupyter Lab
After=network.target

[Service]
Type=simple
User=root
Environment=PATH=/opt/miniconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/miniconda3/bin/jupyter lab --config=/etc/jupyter/jupyter_lab_config.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Jupyter service
systemctl daemon-reload
systemctl enable jupyter
systemctl start jupyter

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
* - Jupyter Lab (running on port 8888)        *
* - VS Code Server (code-server)              *
*                                               *
* Connect with VS Code using Remote-SSH        *
* Jupyter Lab: http://VM_IP:8888              *
* VS Code Server: code-server --bind-addr     *
*                 0.0.0.0:8080                 *
*                                               *
*************************************************
EOF

# Set up user home directory properly
if ! id "de-user" &>/dev/null; then
    useradd -m -s /bin/bash de-user
    usermod -aG docker de-user
    usermod -aG sudo de-user
fi

# Set ownership for user directories
chown -R de-user:de-user /home/de-user/

# Clean up
rm -f /tmp/Miniconda3-latest-Linux-x86_64.sh
apt-get autoremove -y
apt-get autoclean

echo "VM setup completed successfully!"
echo "You can now connect via SSH or use Jupyter Lab at http://VM_IP:8888"
