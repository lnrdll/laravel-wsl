#! /bin/bash
#
#==============================================================================
#
###     Laravel Dev Environment Bootstrap
#
#==============================================================================

PHP="7.3"

#
# format output
#
function output ()
{

local HOSTNAME=$(hostname)
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RESET="\e[0m"
echo -e "${YELLOW}==> ${GREEN}$HOSTNAME: ${RESET}$@ ..."

}

#
# Boostrap
#
output "Update OS"
sudo apt-get update -y &> /dev/null
sudo apt-get upgrade -y &> /dev/null

output "Install PHP and supporting libraries"
sudo apt-get install -y php-xdebug php-fpm php-mysql php$PHP-cli php$PHP-curl php$PHP-mbstring php$PHP-xml php$PHP-zip php$PHP-intl curl git unzip php-cli network-manager libnss3-tools jq xsel &> /dev/null

output "Download and install composer"
cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php &> /dev/null
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer &> /dev/null

output "Configure and update composer"
mkdir ~/.composer
sudo cat > ~/.composer/composer.json << EOF
{
    "require": {
    "valeryan/valet-wsl": "dev-master"
    },
    "repositories": [
    {
        "type": "vcs",
        "url": "git@github.com:valeryan/valet-wsl.git"
    }
    ]
}
EOF
sudo chown -R $USER ~/.composer
composer global update &> /dev/null

cat >> ~/.bashrc << EOF
export PATH="$PATH:$HOME/.composer/vendor/bin"
EOF

output "Install valet"
~/.composer/vendor/bin/valet install &> /dev/null

output "Install Mariadb Server"
sudo apt-get install -qq mariadb-server &> /dev/null

sudo debconf-set-selections <<< "maria-db mysql-server/root_password password "
sudo debconf-set-selections <<< "maria-db mysql-server/root_password_again password "

sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

MYSQL=`which mysql`

Q1="use mysql;"
Q2="update user set plugin='' where User='root';"
Q3="update user set host='%' where User='root';"
Q4="flush privileges;"
SQL="${Q1}${Q2}${Q3}${Q4}"

sudo $MYSQL -uroot -e "$SQL"
sudo service mysql restart

output "Install Redis Server"
sudo apt-get install -y redis-server &> /dev/null
sudo service redis-server start

output "Create startup script"
cat > ~/start-services.sh << EOF
#!/bin/bash

if ps ax | grep -v grep | grep 'php-fpm' > /dev/null
    then
        echo 'FPM is running'
    else
        sudo service php$PHP-fpm start
fi

if ps ax | grep -v grep | grep 'nginx' > /dev/null
    then
        echo 'Nginx is running'
    else
        sudo service nginx start
fi

if ps ax | grep -v grep | grep 'mysql' > /dev/null
    then
        echo 'MySQL is running'
    else
        sudo service mysql start
fi

if ps ax | grep -v grep | grep 'redis-server' > /dev/null
    then
        echo 'Redis is running'
    else
        sudo service redis-server start
fi
EOF

chmod +x ~/start-services.sh

output "Install and configure vim"
sudo apt-get install -y vim &> /dev/null
mkdir -p ~/.vim/colors
curl -o ~/.vim/colors/gruvbox.vim -O https://raw.githubusercontent.com/morhetz/gruvbox/master/colors/gruvbox.vim &> /dev/null
cat >> ~/.vimrc << EOF
set number
syntax enable
set background=dark
colorscheme gruvbox
set mouse=a

if &term =~ '256color'
" disable Background Color Erase (BCE) so that color schemes
" render properly when inside 256-color tmux and GNU screen.
" see also http://snk.tuxfamily.org/log/vim-256color-bce.html
set t_ut=
endif
EOF

echo "alias vi=vim" >> ~/.bashrc
source ~/.bashrc

output "Configure xdebug"
sudo cat >> /etc/php/$PHP/fpm/conf.d/20-xdebug.ini << EOF
xdebug.default_enable=1
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port = 9001
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.remote_autostart=1
EOF

sudo service php$PHP-fpm restart
