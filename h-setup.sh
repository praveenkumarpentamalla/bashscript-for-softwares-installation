#!/bin/bash

# ==============================================================
# Hostinger VPS Provisioning Script
#
# Installs:
#   - Ubuntu user
#   - Docker
#   - Docker Compose
#   - Nginx
#   - PostgreSQL 16
#   - PostgreSQL remote access
#   - PostgreSQL client
#   - MySQL client
#   - Certbot
#
# PostgreSQL remote access:
#   0.0.0.0/0
#
# IMPORTANT:
#   PostgreSQL will be accessible from the internet.
#   Use strong database passwords and preferably restrict
#   port 5432 in Hostinger firewall/security rules.
# ==============================================================

set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

USERNAME="ubuntu"
HOME_DIR="/home/${USERNAME}"

POSTGRES_VERSION="16"
POSTGRES_PORT="5432"

echo ""
echo "=============================================================="
echo " Starting VPS Provisioning"
echo "=============================================================="
echo ""

# ==============================================================
# 1. Check root
# ==============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    echo ""
    echo "Run:"
    echo "sudo bash $0"
    exit 1
fi

echo "==> Running as root"

# ==============================================================
# 2. Prevent interactive package prompts
# ==============================================================

export DEBIAN_FRONTEND=noninteractive

echo "==> Configuring non-interactive package installation"

# ==============================================================
# 3. Update system
# ==============================================================

echo ""
echo "==> Updating package lists"

apt-get update -y

echo ""
echo "==> Upgrading installed packages"

apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

# ==============================================================
# 4. Install basic prerequisites
# ==============================================================

echo ""
echo "==> Installing prerequisites"

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    sudo \
    unzip \
    git \
    vim \
    net-tools \
    jq

# ==============================================================
# 5. Create ubuntu user
# ==============================================================

echo ""
echo "==> Configuring ubuntu user"

if id "${USERNAME}" >/dev/null 2>&1; then

    echo "User '${USERNAME}' already exists."

else

    echo "Creating user '${USERNAME}'..."

    useradd \
        --create-home \
        --home-dir "${HOME_DIR}" \
        --shell /bin/bash \
        "${USERNAME}"

    echo "User '${USERNAME}' created."

fi

# Make sure home directory exists

mkdir -p "${HOME_DIR}"

# ==============================================================
# 6. Add ubuntu to sudo group
# ==============================================================

echo "==> Adding ubuntu user to sudo group"

usermod -aG sudo "${USERNAME}"

# ==============================================================
# 7. Add ubuntu to docker group later
# ==============================================================

# ==============================================================
# 8. Configure SSH directory
# ==============================================================

echo "==> Configuring SSH directory"

mkdir -p "${HOME_DIR}/.ssh"

chmod 700 "${HOME_DIR}/.ssh"

if [ -f /root/.ssh/authorized_keys ]; then

    echo "==> Copying root SSH keys to ubuntu user"

    cp /root/.ssh/authorized_keys \
        "${HOME_DIR}/.ssh/authorized_keys"

    chmod 600 "${HOME_DIR}/.ssh/authorized_keys"

fi

# Ownership

chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}"

# ==============================================================
# 9. Configure passwordless sudo
# ==============================================================

echo "==> Configuring passwordless sudo"

cat > "/etc/sudoers.d/${USERNAME}" <<EOF
${USERNAME} ALL=(ALL) NOPASSWD:ALL
EOF

chmod 440 "/etc/sudoers.d/${USERNAME}"

visudo -cf "/etc/sudoers.d/${USERNAME}"

# ==============================================================
# 10. Install Docker
# ==============================================================

echo ""
echo "=============================================================="
echo " Installing Docker"
echo "=============================================================="

echo "==> Removing old Docker packages"

apt-get remove -y \
    docker \
    docker-engine \
    docker.io \
    containerd \
    runc \
    docker-compose \
    docker-compose-v2 \
    2>/dev/null || true

echo "==> Installing Docker repository prerequisites"

apt-get install -y \
    ca-certificates \
    curl \
    gnupg

echo "==> Creating Docker keyring"

install -m 0755 -d /etc/apt/keyrings

rm -f /etc/apt/keyrings/docker.gpg

curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor \
    -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Adding Docker repository"

. /etc/os-release

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable
EOF

echo "==> Updating package list"

apt-get update -y

echo "==> Installing Docker"

apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "==> Enabling Docker"

systemctl enable docker

systemctl start docker

# Add ubuntu user to docker group

echo "==> Adding ubuntu user to docker group"

groupadd docker 2>/dev/null || true

usermod -aG docker "${USERNAME}"

# ==============================================================
# 11. Verify Docker
# ==============================================================

echo ""
echo "==> Docker version"

docker --version

echo ""
echo "==> Docker Compose version"

docker compose version

# ==============================================================
# 12. Install Nginx
# ==============================================================

echo ""
echo "=============================================================="
echo " Installing Nginx"
echo "=============================================================="

apt-get install -y nginx

systemctl enable nginx

systemctl start nginx

echo "==> Nginx installed"

nginx -v

# ==============================================================
# 13. PostgreSQL PGDG repository
# ==============================================================

echo ""
echo "=============================================================="
echo " Installing PostgreSQL ${POSTGRES_VERSION}"
echo "=============================================================="

echo "==> Installing PostgreSQL repository prerequisites"

apt-get install -y \
    postgresql-common \
    ca-certificates \
    curl

echo "==> Installing PostgreSQL repository"

install -d /usr/share/postgresql-common/pgdg

curl -o \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    --fail \
    https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Get Ubuntu codename

. /etc/os-release

echo "Detected Ubuntu/Debian codename: ${VERSION_CODENAME}"

# Add PGDG repository

cat > /etc/apt/sources.list.d/pgdg.sources <<EOF
Types: deb
URIs: https://apt.postgresql.org/pub/repos/apt
Suites: ${VERSION_CODENAME}-pgdg
Architectures: $(dpkg --print-architecture)
Components: main
Signed-By: /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
EOF

echo "==> Updating package lists"

apt-get update -y

# ==============================================================
# 14. Install PostgreSQL 16
# ==============================================================

echo "==> Installing PostgreSQL ${POSTGRES_VERSION}"

apt-get install -y \
    postgresql-${POSTGRES_VERSION} \
    postgresql-client-${POSTGRES_VERSION}

# ==============================================================
# 15. Enable PostgreSQL
# ==============================================================

echo "==> Enabling PostgreSQL"

systemctl enable postgresql

systemctl start postgresql

# ==============================================================
# 16. Detect PostgreSQL configuration
# ==============================================================

echo "==> Detecting PostgreSQL configuration"

PG_CONFIG_FILE="/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf"

PG_HBA_FILE="/etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf"

if [ ! -f "${PG_CONFIG_FILE}" ]; then
    echo "ERROR: PostgreSQL configuration file not found:"
    echo "${PG_CONFIG_FILE}"
    exit 1
fi

if [ ! -f "${PG_HBA_FILE}" ]; then
    echo "ERROR: PostgreSQL pg_hba.conf not found:"
    echo "${PG_HBA_FILE}"
    exit 1
fi

# ==============================================================
# 17. Backup PostgreSQL configuration
# ==============================================================

echo "==> Backing up PostgreSQL configuration"

cp "${PG_CONFIG_FILE}" \
    "${PG_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"

cp "${PG_HBA_FILE}" \
    "${PG_HBA_FILE}.backup.$(date +%Y%m%d%H%M%S)"

# ==============================================================
# 18. Configure PostgreSQL listen_addresses
# ==============================================================

echo "==> Configuring PostgreSQL remote connections"

# Remove existing listen_addresses lines

sed -i \
    '/^[[:space:]]*listen_addresses[[:space:]]*=/d' \
    "${PG_CONFIG_FILE}"

# Add new configuration

cat >> "${PG_CONFIG_FILE}" <<EOF

# --------------------------------------------------------------
# Remote PostgreSQL access
# Added by VPS provisioning script
# --------------------------------------------------------------

listen_addresses = '*'

port = ${POSTGRES_PORT}

EOF

# ==============================================================
# 19. Configure pg_hba.conf
# ==============================================================

echo "==> Configuring PostgreSQL authentication"

cat >> "${PG_HBA_FILE}" <<EOF

# --------------------------------------------------------------
# Remote IPv4 connections
# Added by VPS provisioning script
# --------------------------------------------------------------

host    all             all             0.0.0.0/0               scram-sha-256

# Remote IPv6 connections

host    all             all             ::/0                    scram-sha-256

EOF

# ==============================================================
# 20. Restart PostgreSQL
# ==============================================================

echo "==> Restarting PostgreSQL"

systemctl restart postgresql

# ==============================================================
# 21. Verify PostgreSQL
# ==============================================================

echo ""
echo "==> PostgreSQL status"

systemctl --no-pager --full status postgresql || true

echo ""
echo "==> PostgreSQL version"

sudo -u postgres psql --version

echo ""
echo "==> Checking PostgreSQL listening port"

ss -lntp | grep ":${POSTGRES_PORT}" || true

# ==============================================================
# 22. Set PostgreSQL postgres user password
# ==============================================================

echo ""
echo "=============================================================="
echo " PostgreSQL password"
echo "=============================================================="

echo ""
echo "PostgreSQL has been configured for remote connections."
echo ""
echo "IMPORTANT:"
echo "You should set a strong password for the postgres user."
echo ""
echo "Run:"
echo ""
echo "sudo -u postgres psql"
echo ""
echo "Then:"
echo ""
echo "\\password postgres"
echo ""
echo "Then:"
echo "\\q"
echo ""

# ==============================================================
# 23. Install MySQL client
# ==============================================================

echo ""
echo "=============================================================="
echo " Installing MySQL client"
echo "=============================================================="

apt-get install -y mysql-client

echo "==> MySQL client version"

mysql --version

# ==============================================================
# 24. Install Certbot
# ==============================================================

echo ""
echo "=============================================================="
echo " Installing Certbot"
echo "=============================================================="

apt-get install -y \
    certbot \
    python3-certbot-nginx

echo "==> Certbot version"

certbot --version

# ==============================================================
# 25. Configure UFW
# ==============================================================

echo ""
echo "=============================================================="
echo " Configuring firewall"
echo "=============================================================="

if command -v ufw >/dev/null 2>&1; then

    echo "==> UFW detected"

    # Allow SSH
    ufw allow 22/tcp || true

    # HTTP
    ufw allow 80/tcp || true

    # HTTPS
    ufw allow 443/tcp || true

    # PostgreSQL
    ufw allow 5432/tcp || true

    echo "==> UFW rules configured"

else

    echo "UFW not installed."
    echo "Skipping UFW configuration."

fi

# ==============================================================
# 26. Clean packages
# ==============================================================

echo ""
echo "==> Cleaning unnecessary packages"

apt-get autoremove -y

apt-get clean

# ==============================================================
# 27. Fix ubuntu ownership
# ==============================================================

echo "==> Fixing ubuntu home directory ownership"

chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}"

# ==============================================================
# 28. Final verification
# ==============================================================

echo ""
echo "=============================================================="
echo " FINAL VERIFICATION"
echo "=============================================================="

echo ""

echo "---- Ubuntu User ----"

id "${USERNAME}"

echo ""

echo "---- Home Directory ----"

ls -ld "${HOME_DIR}"

echo ""

echo "---- Docker ----"

docker --version

echo ""

echo "---- Docker Compose ----"

docker compose version

echo ""

echo "---- Nginx ----"

nginx -v

echo ""

echo "---- PostgreSQL ----"

sudo -u postgres psql --version

echo ""

echo "---- PostgreSQL Port ----"

ss -lntp | grep ":${POSTGRES_PORT}" || true

echo ""

echo "---- MySQL Client ----"

mysql --version

echo ""

echo "---- Certbot ----"

certbot --version

echo ""

echo "---- Services ----"

systemctl is-active docker
systemctl is-active nginx
systemctl is-active postgresql

echo ""
echo "=============================================================="
echo " VPS PROVISIONING COMPLETED"
echo "=============================================================="

echo ""
echo "Ubuntu user:"
echo "    ${USERNAME}"

echo ""
echo "Home directory:"
echo "    ${HOME_DIR}"

echo ""
echo "PostgreSQL:"
echo "    Version: ${POSTGRES_VERSION}"
echo "    Port:    ${POSTGRES_PORT}"
echo "    Listen:  0.0.0.0"

echo ""
echo "Docker:"
echo "    Installed"

echo ""
echo "Nginx:"
echo "    Installed"

echo ""
echo "Certbot:"
echo "    Installed"

echo ""
echo "=============================================================="
echo " IMPORTANT"
echo "=============================================================="

echo ""
echo "1. Set a strong PostgreSQL postgres password:"
echo ""
echo "   sudo -u postgres psql"
echo "   \\password postgres"
echo "   \\q"

echo ""
echo "2. Test SSH using:"
echo ""
echo "   ssh ubuntu@YOUR_SERVER_IP"

echo ""
echo "3. Ubuntu Docker group takes effect after a new login."
echo ""

echo "4. PostgreSQL remote connection:"
echo ""
echo "   Host: YOUR_SERVER_IP"
echo "   Port: 5432"
echo "   User: postgres"
echo "   Password: YOUR_POSTGRES_PASSWORD"
echo ""

echo "=============================================================="

# ==============================================================
# 29. Setup MinIO
# ==============================================================

echo ""
echo "=============================================================="
echo " Setting up MinIO"
echo "=============================================================="

MINIO_DIR="/home/ubuntu/minio"

echo "==> Creating MinIO directory"

mkdir -p "${MINIO_DIR}"
mkdir -p "${MINIO_DIR}/data"
mkdir -p "${MINIO_DIR}/config"

# ==============================================================
# 30. Create MinIO docker-compose.yml
# ==============================================================

echo "==> Creating MinIO docker-compose.yml"

cat > "${MINIO_DIR}/docker-compose.yml" <<'EOF'
version: "3.8"

services:
  minio:
    image: quay.io/minio/minio:RELEASE.2022-02-18T01-50-10Z
    container_name: minio
    command: minio server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: accountiez
      MINIO_ROOT_PASSWORD: Admin@123
    volumes:
      - ./data:/data
      - ./config:/root/.minio
    networks:
      - minio-net
    restart: unless-stopped

networks:
  minio-net:
    driver: bridge
EOF

# ==============================================================
# 31. Set ownership
# ==============================================================

echo "==> Setting MinIO directory ownership"

chown -R ubuntu:ubuntu "${MINIO_DIR}"

# ==============================================================
# 32. Start MinIO
# ==============================================================

echo "==> Starting MinIO Docker Compose"

cd "${MINIO_DIR}"

sudo -u ubuntu docker compose up -d

# ==============================================================
# 33. Verify MinIO container
# ==============================================================

echo ""
echo "==> Checking MinIO container"

docker ps --filter "name=minio"

# ==============================================================
# 34. Show MinIO logs
# ==============================================================

echo ""
echo "==> Recent MinIO logs"

docker logs --tail 20 minio || true

# ==============================================================
# 35. Check ports
# ==============================================================

echo ""
echo "==> Checking MinIO ports"

ss -lntp | grep -E ':9000|:9001' || true

# ==============================================================
# 36. Final MinIO information
# ==============================================================

echo ""
echo "=============================================================="
echo " MinIO Setup Completed"
echo "=============================================================="

echo ""
echo "MinIO directory:"
echo "    ${MINIO_DIR}"

echo ""
echo "Docker Compose file:"
echo "    ${MINIO_DIR}/docker-compose.yml"

echo ""
echo "MinIO S3 API:"
echo "    http://YOUR_SERVER_IP:9000"

echo ""
echo "MinIO Web Console:"
echo "    http://YOUR_SERVER_IP:9001"

echo ""
echo "MinIO Username:"
echo "    accountiez"

echo ""
echo "MinIO Password:"
echo "    Admin@123"


# ==============================================================
# 8. Configure SSH key for ubuntu user
# ==============================================================

echo ""
echo "=============================================================="
echo " Configuring SSH key for ubuntu user"
echo "=============================================================="

SSH_DIR="/home/ubuntu/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

echo "==> Creating SSH directory"

mkdir -p "${SSH_DIR}"

# ==============================================================
# Add SSH public key
# ==============================================================

echo "==> Adding SSH public key"

cat > "${AUTHORIZED_KEYS}" <<'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCV4g+ml+NG8Yn45grix7jetw6F/JdXc19ErgIYEOXFneVWCPJFIW4M0rhBZrizUJZYTueOB6KiHJ1bFlhSIxpmJezW8Nqy7L3AdTs4PnQFVXM3oWH95eM0Btmg+DsYZT14aUzZXNdBdHCvwqUQA0v+DMuUjc6lHbnaS1Xu/wMj5X9K2YYLAZ6ogLbC3MinB7jvruBoFsSqVzkwGcZkFPv+1755ZQ+guoIhKtM6FblEFWR5dGVQ1oGXrd9hsp8LMe3JD28wkyNq7ATpFrRF0vjga0snv63yIAN3IQpwIXB9vF4kiVArBa2tezfGFRinooXZ9Dhkuk5FnHsmOdqyTcCWE5WLM7kpt4F25Be5eZVJTbkfjsZxPKbh7vyIKSdnhCOlqqcsLPU8qrH7NZjL4y/PkkHT2kyYEo3uXZz7PJ1gkPRJq/uUuc6UdUMX8sLaxJ14YZBiSb/kgPHaFbNb5CCyc3K7a5x/QR1JnnBAEQCb2gXhnHnelybHNF4beqQJY80KGvyT+n8oXHRsLQr1ChRwCSc5V96eIA4IVM2ESlYnzRP6Ty50p/2X3FpY7btbb8QhQBQrF4KMDCrnnKtbrhAkPpp6av0AOZ0eB3q7wTOAyWlIaffa7AzXiWSUd7HuA7eu348X6mpkA5Xb1+wFZcaghXI2Cya4rbokxJBnMG50qQ==praveenkumarpentamalla@gmail.com
EOF

# ==============================================================
# SSH permissions
# ==============================================================

echo "==> Setting SSH permissions"

chmod 700 "${SSH_DIR}"

chmod 600 "${AUTHORIZED_KEYS}"

chown -R ubuntu:ubuntu "${SSH_DIR}"

# Make sure the home directory itself has correct ownership
chown ubuntu:ubuntu "/home/ubuntu"

# ==============================================================
# Verify SSH key
# ==============================================================

echo "==> Verifying SSH configuration"

echo ""
echo "SSH directory:"
ls -ld "${SSH_DIR}"

echo ""
echo "authorized_keys:"
ls -l "${AUTHORIZED_KEYS}"

echo ""
echo "authorized_keys permissions:"
stat -c "%A %U:%G %n" "${AUTHORIZED_KEYS}"

echo ""
echo "SSH key configured successfully."

# ==============================================================
# 9. Configure passwordless sudo
# ==============================================================

echo ""
echo "=============================================================="
echo " Configuring sudo"
echo "=============================================================="

cat > "/etc/sudoers.d/ubuntu" <<'EOF'
ubuntu ALL=(ALL) NOPASSWD:ALL
EOF

chmod 440 /etc/sudoers.d/ubuntu

visudo -cf /etc/sudoers.d/ubuntu

echo "==> Passwordless sudo configured for ubuntu"

echo ""
echo "=============================================================="
