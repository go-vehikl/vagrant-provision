#!/usr/bin/env bash

sudo su -

echo ">>> Starting Install Script"

# Update
#sudo apt-get update

# Install base items
echo ">>> Installing Base Items"
#sudo apt-get install -y vim curl wget build-essential python-software-properties git-core
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

# Install Apache2
echo ">>> Installing Apache"
yum -y install httpd
/etc/init.d/httpd start

# Install MySQL
echo ">>> Installing MySQL"
yum -y install mysql-server
/etc/init.d/mysqld start
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -u root -e "CREATE DATABASE development;"
#mysql -u root development < /vagrant/sql/dump.sql

# Install PHP
echo ">>> Installing PHP"
yum -y --enablerepo=epel,remi,rpmforge install php php-mysql php-devel php-mcrypt php-xdebug
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php.ini

echo    "User vagrant
        Group vagrant" >> /etc/httpd/conf/httpd.conf

echo    "<VirtualHost *:80>
                <Directory /var/www/html>
                    AllowOverride all
                </Directory>

                ServerAdmin webmaster@localhost
                DocumentRoot /var/www/html
                SetEnv APPLICATION_ENV \"development\"
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>" > /etc/httpd/conf.d/default.conf

/etc/init.d/httpd restart

echo ">>> Linking Webroot"
cd /var/www
rm -rf html
ln -s /vagrant/src/public/ html
