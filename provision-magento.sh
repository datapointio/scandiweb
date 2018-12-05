#!/bin/bash

apt-get update
apt-get install -y nginx
add-apt-repository ppa:ondrej/php -y
apt-get install -y php7.1-fpm php7.1-mcrypt php7.1-curl php7.1-cli php7.1-mysql php7.1-gd php7.1-xsl php7.1-json php7.1-intl php-pear php7.1-dev php7.1-common php7.1-mbstring php7.1-zip php7.1-soap php7.1-bcmath
apt-get install -y mysql-server mysql-client
apt-get install -y composer

mysql -u root -p0 -e "CREATE DATABASE magentodb; CREATE USER magentouser@localhost IDENTIFIED BY '$1'; GRANT ALL PRIVILEGES ON magentodb.* TO magentouser@localhost IDENTIFIED BY '$1'; FLUSH PRIVILEGES;"

cd /var/www
wget https://github.com/magento/magento2/archive/2.2.4.tar.gz
tar -xf 2.2.4.tar.gz
mv magento2-2.2.4/ magento2/

cd /var/www/magento2
composer install -v

chown -R www-data:www-data /var/www/magento2/

cat >/etc/nginx/sites-available/default <<EOL
upstream fastcgi_backend {
        server  unix:/run/php/php7.1-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    set \$MAGE_ROOT /var/www/magento2;
    set \$MAGE_MODE production;
    include /var/www/magento2/nginx.conf.sample;
}
EOL

systemctl restart php7.1-fpm
systemctl restart nginx

exit 0
