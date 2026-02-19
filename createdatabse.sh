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





# sudo apt update
# sudo apt install -y postgresql
# DB_NAME="dbname" 
# USER_NAME="dbuser" 
# PASSWORD="dbpassword@123" 


# sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
# sudo -u postgres psql -c "CREATE USER $USER_NAME WITH ENCRYPTED PASSWORD '$PASSWORD';"
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $USER_NAME;"
# sudo -u postgres psql -c "ALTER USER $USER_NAME CREATEDB;"
# #sudo -u postgres createuser --superuser $SUPER_USERNAME
# #sudo -u postgres psql -c "ALTER USER $SUPER_USERNAME WITH ENCRYPTED PASSWORD '$SUPERUSER_PASSWORD';"


# sudo sh -c "echo 'local all all md5' >> /etc/postgresql/16/main/pg_hba.conf"
# sudo systemctl restart postgresql

# #echo "PostgreSQL installed successfully!"
# #echo "Database name: $DB_NAME"
# #echo "User name: $USER_NAME"
# #echo "Password: $PASSWORD"
