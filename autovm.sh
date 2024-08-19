#!/bin/bash

PHP_VERSION=7.4
PHP_VERSION_SHORT=74

# Nginx configuration
config="server {
  listen 80;

  server_name localhost;

  index index.php;
  root /var/www/autovm/web;

  location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
  }

  location ~ \\.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
  }

  location ~ \\.ht {
    deny all;
  }
}"


apt install apt-transport-https ca-certificates curl software-properties-common -y

apt install unzip nginx mysql-server-core-8.0 mysql-server python3-pip -y
add-apt-repository universe
apt update 
apt install python2
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
python2 get-pip.py

apt install libpq-dev python-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev libffi-dev git -y

apt install php -y 

add-apt-repository ppa:ondrej/php
apt-get install php$PHP_VERSION php$PHP_VERSION-dev php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-mbstring  php$PHP_VERSION-mysql php$PHP_VERSION-common php$PHP_VERSION-fpm libtool-bin libc6-dev build-essential make autoconf libc-dev pkg-config php-pear postfix   gcc libreadline-dev   php$PHP_VERSION-cgi php$PHP_VERSION-zip php$PHP_VERSION-pdo-mysql php$PHP_VERSION-xml   php$PHP_VERSION-cli php$PHP_VERSION-imagick imagemagick  php$PHP_VERSION-intl php$PHP_VERSION-memcache php$PHP_VERSION-memcached php$PHP_VERSION-geoip php$PHP_VERSION-memcached php$PHP_VERSION-snmp php$PHP_VERSION-sqlite php$PHP_VERSION-tidy php$PHP_VERSION-xmlrpc php$PHP_VERSION-xsl memcached snmp php$PHP_VERSION-ps php$PHP_VERSION-pspell libphonenumber-dev libphonenumber7 -y

# Update repositories
apt update -y

# Install requirements
apt install -y nginx git unzip php$PHP_VERSION-fpm php$PHP_VERSION-cli php$PHP_VERSION-mysql php$PHP_VERSION-mbstring php$PHP_VERSION-gd php$PHP_VERSION-curl php$PHP_VERSION-zip php$PHP_VERSION-xml mysql-server python3-pip && pip install -y spur pysphere crypto netaddr

# Random password
password=$(openssl rand -base64 16)

# PHP config
php_config="<?php
return [
    'class' => 'yii\db\Connection',
    'dsn' => 'mysql:host=localhost;dbname=autovm',
    'username' => 'autovm',
    'password' => '$password',
    'charset' => 'utf8',
];"

# Configure MySQL
mysql -u root -e "CREATE USER autovm@localhost IDENTIFIED WITH mysql_native_password BY '$password';GRANT ALL PRIVILEGES ON *.* TO autovm@localhost; FLUSH PRIVILEGES;CREATE DATABASE autovm DEFAULT CHARACTER SET utf8;"

# Configure Nginx
sed -i 's/# multi_accept on/multi_accept on/' /etc/nginx/nginx.conf && echo $config > /etc/nginx/sites-available/default && service nginx restart

# Configure PHP
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/$PHP_VERSION/fpm/php.ini && service php$PHP_VERSION-fpm restart

# Configure AutoVM
cd /var/www && rm -rf html && git clone https://github.com/Adekabang/autovm_old.git autovm && cd autovm && php$PHP_VERSION composer.phar install && echo $php_config > /var/www/autovm/config/db.php && mysql -u root -proot autovm < database.sql && mysql -u root -e "USE autovm;UPDATE user SET auth_key = '$password'" && php$PHP_VERSION yii migrate --interactive=0 && chmod -R 0777 /var/www/autovm

# Configure Cron
cd /tmp && echo -e "*/5 * * * * php /var/www/autovm/yii cron/index\n0 0 * * * php /var/www/autovm/yii cron/reset" > cron && crontab cron

# Find address
address=$(ip address | grep "scope global" | grep -Po '(?<=inet )[\d.]+')

# MySQL details
clear && echo -e "\033[104mThe platform installation has been completed successfully.\033[0m\n\nMySQL information:\nUsername: autovm\nDatabase: autovm\nPassword: \033[0;32m$password\033[0m\n\n\nLogin information:\nAddress: http://$address\nUsername: admin@admin.com\nPassword: admin\n\nAttention: Please run \033[0;31mmysql_secure_installation\033[0m for the security"
