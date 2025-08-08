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
