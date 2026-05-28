#!/bin/bash
set -e

# ====== CONFIG ======
DB_NAME="saubhagyadb"
USER_NAME="saubhagyauser"
PASSWORD="k1DqDJk03J"
PG_VERSION="16"
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

echo "🔄 Updating packages..."
sudo apt update

echo "📦 Installing PostgreSQL 16..."
sudo apt install -y postgresql-16

echo "🚀 Enabling PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "🗄️ Creating database and user..."
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
      CREATE DATABASE $DB_NAME;
   END IF;
END
\$\$;

DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$USER_NAME') THEN
      CREATE USER $USER_NAME WITH ENCRYPTED PASSWORD '$PASSWORD';
   END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $USER_NAME;
ALTER USER $USER_NAME CREATEDB;
EOF

echo "🔐 Fixing schema permissions for PostgreSQL 16 (Django requirement)..."
sudo -u postgres psql -d "$DB_NAME" <<EOF
GRANT USAGE ON SCHEMA public TO $USER_NAME;
GRANT CREATE ON SCHEMA public TO $USER_NAME;
ALTER SCHEMA public OWNER TO $USER_NAME;
EOF

# ─── Allow Remote Connections ─────────────────────────────────────────────────

echo "🌐 Configuring PostgreSQL to listen on all interfaces..."
# Set listen_addresses = '*' in postgresql.conf
if grep -q "^#listen_addresses" "$PG_CONF"; then
    sudo sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
elif grep -q "^listen_addresses" "$PG_CONF"; then
    sudo sed -i "s/^listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
else
    echo "listen_addresses = '*'" | sudo tee -a "$PG_CONF"
fi

echo "⚙️ Updating pg_hba.conf for local and remote access..."

# Remove conflicting existing rules (optional safety clean)
sudo sed -i '/^host.*all.*all.*0\.0\.0\.0\/0/d' "$PG_HBA"
sudo sed -i '/^host.*all.*all.*::\/0/d' "$PG_HBA"

# Local access with md5
if ! sudo grep -qP "^local\s+all\s+all\s+md5" "$PG_HBA"; then
    echo "local   all             all                                     md5" | sudo tee -a "$PG_HBA"
fi

# Remote access from anywhere (IPv4)
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a "$PG_HBA"

# Remote access from anywhere (IPv6)
echo "host    all             all             ::/0                    md5" | sudo tee -a "$PG_HBA"

echo "🔄 Restarting PostgreSQL..."
sudo systemctl restart postgresql

# ─── Firewall ─────────────────────────────────────────────────────────────────
echo "🛡️ Opening port 5432 in firewall..."
if command -v ufw &>/dev/null; then
    sudo ufw allow 5432/tcp
    sudo ufw --force enable
    sudo ufw status
else
    echo "⚠️  ufw not found — if using iptables or a cloud firewall (AWS/GCP/Azure security group), open port 5432 manually."
fi

# ─── Verify ───────────────────────────────────────────────────────────────────
echo ""
echo "✅ PostgreSQL 16 setup completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Host:      $(hostname -I | awk '{print $1}')"
echo "  Port:      5432"
echo "  Database:  $DB_NAME"
echo "  User:      $USER_NAME"
echo "  Password:  $PASSWORD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Connection string:"
echo "  postgresql://$USER_NAME:$PASSWORD@$(hostname -I | awk '{print $1}'):5432/$DB_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  SECURITY REMINDER: '0.0.0.0/0' allows ALL IPs."
echo "   Restrict to specific IPs in pg_hba.conf when possible."






#!/bin/bash
set -e

# ====== CONFIG ======
DB_NAME="dbname"
USER_NAME="dbuser"
PASSWORD="dbpassword@123"
PG_VERSION="16"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

echo "🔄 Updating packages..."
sudo apt update

echo "📦 Installing PostgreSQL 16..."
sudo apt install -y postgresql-16

echo "🚀 Enabling PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "🗄️ Creating database and user..."

sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
      CREATE DATABASE $DB_NAME;
   END IF;
END
\$\$;

DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$USER_NAME') THEN
      CREATE USER $USER_NAME WITH ENCRYPTED PASSWORD '$PASSWORD';
   END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $USER_NAME;
ALTER USER $USER_NAME CREATEDB;
EOF

echo "🔐 Fixing schema permissions for PostgreSQL 16 (Django requirement)..."

sudo -u postgres psql -d "$DB_NAME" <<EOF
GRANT USAGE ON SCHEMA public TO $USER_NAME;
GRANT CREATE ON SCHEMA public TO $USER_NAME;
ALTER SCHEMA public OWNER TO $USER_NAME;
EOF

echo "⚙️ Updating pg_hba.conf..."

if ! grep -q "^local\s\+all\s\+all\s\+md5" "$PG_HBA"; then
    echo "local all all md5" | sudo tee -a "$PG_HBA"
fi

echo "🔄 Restarting PostgreSQL..."
sudo systemctl restart postgresql

echo "✅ PostgreSQL 16 setup completed!"
echo "Database name: $DB_NAME"
echo "User name: $USER_NAME"
echo "Password: $PASSWORD"





sudo apt update
sudo apt install -y postgresql
DB_NAME="dbname" 
USER_NAME="dbuser" 
PASSWORD="dbpassword@123" 


sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $USER_NAME WITH ENCRYPTED PASSWORD '$PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $USER_NAME;"
sudo -u postgres psql -c "ALTER USER $USER_NAME CREATEDB;"
#sudo -u postgres createuser --superuser $SUPER_USERNAME
#sudo -u postgres psql -c "ALTER USER $SUPER_USERNAME WITH ENCRYPTED PASSWORD '$SUPERUSER_PASSWORD';"


sudo sh -c "echo 'local all all md5' >> /etc/postgresql/16/main/pg_hba.conf"
sudo systemctl restart postgresql

#echo "PostgreSQL installed successfully!"
#echo "Database name: $DB_NAME"
#echo "User name: $USER_NAME"
#echo "Password: $PASSWORD"
