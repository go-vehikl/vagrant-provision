#!/usr/bin/env bash

echo ">>> Starting Install Script"

# Update
sudo apt-get update

# Install MySQL without prompt
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

echo ">>> Installing Base Items"

# Install base items
sudo apt-get install -y vim curl wget build-essential python-software-properties

echo ">>> Adding PPA's and Installing Server Items"

# Add repo for latest PHP
sudo add-apt-repository -y ppa:ondrej/php5-oldstable

# Update Again
sudo apt-get update

# Install the Rest
sudo apt-get install -y git-core php5 apache2 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-mcrypt php5-xdebug mysql-server

# Make MySQL accessible remotely
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -u root -proot -e "CREATE DATABASE development;"
mysql -u root -proot development < /vagrant/sql/dump.sql

echo ">>> Configuring Server"

# xdebug Config
cat << EOF | sudo tee -a /etc/php5/mods-available/xdebug.ini
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
EOF

# Apache Config
sudo a2enmod rewrite

# PHP Config
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini

echo    "User vagrant
        Group vagrant" >> /etc/apache2/apache2.conf

echo    "<VirtualHost *:80>
                # The ServerName directive sets the request scheme, hostname and port that
                # the server uses to identify itself. This is used when creating
                # redirection URLs. In the context of virtual hosts, the ServerName
                # specifies what hostname must appear in the request's Host: header to
                # match this virtual host. For the default virtual host (this file) this
                # value is not decisive as it is used as a last resort host regardless.
                # However, you must set it for any further virtual host explicitly.
                #ServerName www.example.com

                <Directory /var/www>
                    AllowOverride all
                </Directory>

                ServerAdmin webmaster@localhost
                DocumentRoot /var/www
                SetEnv APPLICATION_ENV \"development\"

            # Uncomment the FORWARDED_PORT environment variable if you plan on running
            # the vagrant vm unbridged AND you're not working directly on the host
            #SetEnv FORWARDED_PORT 8080

                # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
                # error, crit, alert, emerg.
                # It is also possible to configure the loglevel for particular
                # modules, e.g.
                #LogLevel info ssl:warn

                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined

        </VirtualHost>

        # vim: syntax=apache ts=4 sw=4 sts=4 sr noet" > /etc/apache2/sites-available/default

sudo service apache2 restart

echo ">>> Linking Webroot"

cd /var
sudo rm -rf www
ln -s /vagrant/src/public www

 echo ">>> Installing Composer"

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# install composer dependencies
if [ -f /vagrant/src/composer.json ]; then
    echo ">>> Installing composer dependencies"
    cd /vagrant/src
    composer install --no-scripts
fi

# seed the development database
if [ -f /vagrant/src/artisan ]; then
    echo ">>> Seeding the development database"
    cd /vagrant/src
    php artisan migrate --seed
fi
