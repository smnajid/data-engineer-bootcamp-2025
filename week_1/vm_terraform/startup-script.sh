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

# Install standalone Docker Compose for compatibility
DOCKER_COMPOSE_VERSION="v2.24.1"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

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

# Configure git branch in prompt for all users
# Add to system-wide bashrc
cat >> /etc/bash.bashrc << 'EOF'

# Git branch in prompt
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Set PS1 with git branch for all users
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
EOF

# Configure for zsh users (if zsh is installed)
if command -v zsh &> /dev/null; then
    cat >> /etc/zsh/zshrc << 'EOF'

# Git branch in prompt for zsh
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{red}${vcs_info_msg_0_}%f %% '
EOF
fi

# Add git branch prompt to de-user's bashrc specifically
cat >> /home/de-user/.bashrc << 'EOF'

# Git branch in prompt
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Custom prompt with git branch
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
EOF

# Add git branch prompt to de-user's zshrc if they use zsh
if command -v zsh &> /dev/null; then
    cat >> /home/de-user/.zshrc << 'EOF'

# Git branch in prompt for zsh
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{red}${vcs_info_msg_0_}%f %% '
EOF
fi

# Configure Git for the user
sudo -u de-user bash << 'EOF'
cd /home/de-user

# Set up Git configuration
git config --global user.name "Mohamed NAJID"
git config --global user.email "smnajid@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase false

# Generate SSH key for GitHub authentication
if [ ! -f /home/de-user/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "smnajid@gmail.com" -f /home/de-user/.ssh/id_ed25519 -N ""
    
    # Set proper permissions
    chmod 700 /home/de-user/.ssh
    chmod 600 /home/de-user/.ssh/id_ed25519
    chmod 644 /home/de-user/.ssh/id_ed25519.pub
    
    # Add GitHub to known hosts
    ssh-keyscan -H github.com >> /home/de-user/.ssh/known_hosts
    
    # Create SSH config for GitHub
    cat > /home/de-user/.ssh/config << 'SSH_EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
SSH_EOF
    chmod 600 /home/de-user/.ssh/config
fi

# Clone the data engineering repository
if [ ! -d /home/de-user/data-engineer-bootcamp-2025 ]; then
    # Try SSH first, fallback to HTTPS if SSH key not configured on GitHub yet
    git clone git@github.com:smnajid/data-engineer-bootcamp-2025.git /home/de-user/data-engineer-bootcamp-2025 2>/dev/null || \
    git clone https://github.com/smnajid/data-engineer-bootcamp-2025.git /home/de-user/data-engineer-bootcamp-2025
    
    # If cloned via HTTPS, set remote to SSH for future pushes
    if [ -d /home/de-user/data-engineer-bootcamp-2025 ]; then
        cd /home/de-user/data-engineer-bootcamp-2025
        git remote set-url origin git@github.com:smnajid/data-engineer-bootcamp-2025.git
    fi
fi

# Create a projects directory for additional repositories
mkdir -p /home/de-user/projects

# Create a helpful script to display SSH public key
cat > /home/de-user/show-ssh-key.sh << 'SCRIPT_EOF'
#!/bin/bash
echo "🔑 Your SSH Public Key for GitHub:"
echo "======================================"
cat ~/.ssh/id_ed25519.pub
echo ""
echo "📋 To add this key to GitHub:"
echo "1. Copy the key above"
echo "2. Go to https://github.com/settings/ssh/new"
echo "3. Paste the key and give it a title (e.g., 'DE Zoomcamp VM')"
echo "4. Click 'Add SSH key'"
echo ""
echo "✅ After adding the key, you can push to your repositories!"
SCRIPT_EOF

chmod +x /home/de-user/show-ssh-key.sh

EOF

# Ensure all files are owned by de-user
chown -R de-user:de-user /home/de-user/

# Clean up
rm -f /tmp/Miniconda3-latest-Linux-x86_64.sh
apt-get autoremove -y
apt-get autoclean

echo "VM setup completed successfully!"
echo "You can now connect via SSH or use Jupyter Lab at http://VM_IP:8888"
