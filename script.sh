#!/bin/bash
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y build-essential nginx git virtualenv python3 python3-dev postgresql apt-transport-https ca-certificates curl software-properties-common gnup certbot python3-certbot-nginx

cd /var/www


# git clone https://fpgn-deploy-token:hS4vGkMdKKqD-yevssBu@gitlab.com/premanath.t/flypigeon.git
# git clone https://fpgn-deploy-token:2_gwUkZPhpiezBEK6reP@gitlab.com/ajay.solanke/flypigeon.git
git clone https://fpgn-deploy-token:N16UzjyXUMcUg1Ck6HXc@gitlab.com/ajay.solanke/flypigeon.git


cd flypigeon
git checkout main
sudo usermod -aG ubuntu www-data
sudo chown -R ubuntu:ubuntu /var/www/flypigeon
sudo mkdir media
sudo mkdir /var/www/flypigeon/media/Bus_ETickets
sudo mkdir /var/www/flypigeon/media/EMT_ETickets


sudo touch /var/log/fpgn-access.log
sudo chown www-data:www-data /var/log/fpgn-access.log
sudo touch /var/log/fpgn-error.log
sudo chown www-data:www-data /var/log/fpgn-error.log


virtualenv -p /usr/bin/python3 env
source env/bin/activate
pip install -r requirements_prod.txt


cd ~
git clone https://fpgn-cfg-deploy-token:R4F71xUx6YmzTTF11Ugw@gitlab.com/ajay.solanke/fpgn-cfg.git
cd ~/fpgn-cfg/prod
sudo chmod +x env.sh
./env.sh
source /etc/profile

cd /var/www/flypigeon
python manage.py migrate
python manage.py collectstatic
sudo chown -R ubuntu:ubuntu /var/www/flypigeon

cd ~/fpgn-cfg/prod
sudo mkdir /opt/conf
sudo cp env /opt/conf/env
sudo chown -R ubuntu:www-data /opt/conf
sudo cp config.json /home/ubuntu
sudo cp amazon-cloudwatch-agent.sh /home/ubuntu


sudo cp fpgn.service /etc/systemd/system/fpgn.service

sudo systemctl daemon-reload
sudo systemctl enable fpgn.service
sudo service fpgn start
sudo chmod 775 /var/www/flypigeon/logs
sudo chmod 664 /var/www/flypigeon/logs/*
sudo chown -R ubuntu:ubuntu /var/www/flypigeon
sudo service fpgn restart

sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
sudo cp flypigeon.com /etc/nginx/sites-available/flypigeon.com
sudo ln -s /etc/nginx/sites-available/flypigeon.com /etc/nginx/sites-enabled/
sudo service nginx restart


cd /home/ubuntu
sudo chmod +x amazon-cloudwatch-agent.sh
./amazon-cloudwatch-agent.sh

