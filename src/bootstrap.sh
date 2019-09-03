#! /bin/bash

#====================================================================================
#
#	FILE: bootstrap.sh
#
#	DESCRIPTION: Bootstrap Laravel Dev Environment for WSL Debian
#
#	LICENSE: Apache 2.0
#
#====================================================================================
set -o nounset			# treat unset variables as an error
set -o errexit			# exit script when command fails

# PHP Version to install
PHP="7.3"

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  __check_command_exists
#   DESCRIPTION:  Check if a command exists.
#-------------------------------------------------------------------------------------
__check_command_exists() {
    command -v "$1" > /dev/null 2>&1
}

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  __check_debian
#   DESCRIPTION:  Check if a command exists.
#-------------------------------------------------------------------------------------
__check_debian() {
    cat /etc/os-release | grep -v grep | grep Debian > /dev/null 2>&1
}

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  __check_service_running
#   DESCRIPTION:  Check if a given service is running.
#-------------------------------------------------------------------------------------
__check_service_running() {
    ps -ef | grep -v grep | grep "$1" > /dev/null 2>&1
}

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  __set_colors  
#   DESCRIPTION:  Set terminal colors
#-------------------------------------------------------------------------------------
__set_colors() {
    RC="\e[1;31m"
    GC="\e[1;32m"
    YC="\e[1;33m"
    BC="\e[1;34m"
    WC="\e[0m"
}
__set_colors

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  echoinfo  
#   DESCRIPTION:  format output info
#-------------------------------------------------------------------------------------
function echoinfo() {
    echo -e "${WC}[ ${GC}INFO${WC}  ] $@"
}

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  echoerror  
#   DESCRIPTION:  format output error
#-------------------------------------------------------------------------------------
function echoerror() {
    echo -e "${WC}[ ${RC}ERROR${WC} ] $@"
}

#---  FUNCTION  ----------------------------------------------------------------------
#          NAME:  echowarn  
#   DESCRIPTION:  format output warn
#-------------------------------------------------------------------------------------
function echowarn() {
    echo -e "${WC}[ ${YC}WARN${WC}  ] $@"
}

#-------------------------------------------------------------------------------------
#  Simple warning notification and validation
#-------------------------------------------------------------------------------------
if [ __check_debian ]; then
    echowarn "This script has only been tested on a Debian system. Run it at your own discretion."
fi

echowarn "This setup is NOT suited for production deployments.\n"
sleep 5

#-------------------------------------------------------------------------------------
# Update local OS
#-------------------------------------------------------------------------------------
echoinfo "Update OS"
sudo apt-get update -y &> /dev/null
sudo apt-get upgrade -y &> /dev/null

#-------------------------------------------------------------------------------------
# Install OS packages
#-------------------------------------------------------------------------------------
echoinfo "Install PHP and supporting libraries"
sudo apt-get install -y php-xdebug \
                        php-fpm \
                        php-mysql \
                        php$PHP-cli \
                        php$PHP-curl \
                        php$PHP-mbstring \
                        php$PHP-xml \
                        php$PHP-zip \
                        php$PHP-intl \
                        curl git unzip \
                        php-cli \
                        network-manager \
                        libnss3-tools \
                        jq xsel vim &> /dev/null

#-------------------------------------------------------------------------------------
# Composer
#-------------------------------------------------------------------------------------
echoinfo "Download and install composer"
cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php &> /dev/null
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer &> /dev/null

echoinfo "Configure and update composer"
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

# check if composer command exists
if ! __check_command_exists composer; then
    echoerror "Command 'composer' doesn't exist. Make sure it was correctly installed."
    exit 1
fi

# check if composer config exists
if [ ! -f "~/.composer/composer.json" ]; then
    echoerror "Composer configuration file doesn't exist."
    exit 1
fi

composer global update &> /dev/null

cat >> ~/.bashrc << EOF
export PATH="$PATH:$HOME/.composer/vendor/bin"
EOF

#-------------------------------------------------------------------------------------
# Valet
#-------------------------------------------------------------------------------------
# check valet command exists
if [ ! -f "~/.composer/vendor/bin/valet" ]; then
    echoerror "Valet command doesn't exist. Review your composer install."
    exit 1
fi

echoinfo "Install valet"
~/.composer/vendor/bin/valet install &> /dev/null

#-------------------------------------------------------------------------------------
# Database
#-------------------------------------------------------------------------------------
echoinfo "Install Mariadb Server"
sudo apt-get install -qq mariadb-server &> /dev/null

echoinfo "Configure Mariadb Server"
sudo debconf-set-selections <<< "maria-db mysql-server/root_password password "
sudo debconf-set-selections <<< "maria-db mysql-server/root_password_again password "

sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo service mysql restart &> /dev/null

MYSQL=`which mysql`

Q1="use mysql;"
Q2="update user set plugin='' where User='root';"
Q3="update user set host='%' where User='root';"
Q4="flush privileges;"
SQL="${Q1}${Q2}${Q3}${Q4}"

sudo $MYSQL -uroot -e "$SQL"
sudo service mysql restart &> /dev/null

if ! __check_service_running mysql; then
    echowarn "MYSQL couldn't be started. Review MySQL logs."
fi

#-------------------------------------------------------------------------------------
# Redis
#-------------------------------------------------------------------------------------
echoinfo "Install Redis Server"
sudo apt-get install -y redis-server &> /dev/null
sudo service redis-server start &> /dev/null

if ! __check_service_running redis-server; then
    echowarn "Redis server couldn't be started. Review Redis logs."
fi

#-------------------------------------------------------------------------------------
# CTL Services
#-------------------------------------------------------------------------------------
echoinfo "Create startup script"
SCRIPT_FILE="ctl-services.sh"

cat > ~/"${SCRIPT_FILE}" << EOF
#!/bin/bash

case "${1:-''}" in
  'start');;
  'stop');;
  'restart');;
  'status');;
  *)
    echo "Usage: $SELF start|stop|restart|status"
    exit 1
  ;;
esac

SERVICES=( php-fpm nginx mysql redis-server )

for i in "${SERVICES[@]}"
do
  if [ $i == 'php-fpm' ]
    then
        sudo service php7.3-fpm $1
    else
        sudo service $i $1
  fi
done
EOF

chmod +x ~/"${SCRIPT_FILE}"

if [ ! -f "${SCRIPT_FILE}" ]; then
    echowarn "${SCRIPT_NAME} was not created."
fi

#-------------------------------------------------------------------------------------
# VIM
#-------------------------------------------------------------------------------------
echoinfo "Update vim configuration"
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

#-------------------------------------------------------------------------------------
# XDEBUG
#-------------------------------------------------------------------------------------
echoinfo "Configure xdebug"
cat << EOF | sudo tee -a /etc/php/$PHP/fpm/conf.d/20-xdebug.ini &> /dev/null
xdebug.default_enable=1
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9001
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.remote_autostart=1
EOF

sudo service php$PHP-fpm restart &> /dev/null

if ! __check_service_running php$PHP-fpm ; then
    echowarn "php-fpm service couldn't be started."
fi
