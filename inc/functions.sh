#!/bin/bash
function f_create_user() {
  # Create new user & prompt for password creation
  read -p "Your username: " user
  printf "\n"
  adduser --gecos GECOS $user
  # Add user $user to sudo group
  usermod -a -G sudo $user
}

function f_disable_root_ssh_login() {
  # Disable SSH Root Login
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
}

function f_disable_ssh_password() {
  # Disable SSH Password Authentication
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
}

function f_create_ssh_key() {
  v_root_ssh_keypath="/root/.ssh/authorized_keys"
  # Check root ssh key exist
  if [ -f "$v_root_ssh_keypath" ]; then
    # If exist copy the key to the user and delete the root's key folder
    cp -R /root/.ssh /home/$user/.ssh
    chown -R $user:$user /home/$user/.ssh
    chmod 700 /home/$user/.ssh
    chmod 600 /home/$user/.ssh/authorized_keys
    rm -R /root/.ssh
  else
    sudo -u $user mkdir -p /home/$user/.ssh
    # If not exist create key file to the user
    cat <<EOT >> /home/$user/.ssh/authorized_keys
    $publickey
EOT
    chown -R $user:$user /home/$user/.ssh
    chmod 700 /home/$user/.ssh
    chmod 600 /home/$user/.ssh/authorized_keys
  fi
  service sshd restart
}

function f_create_swap() {
  # Create swap disk image if the system doesn't have swap.
  checkswap="$(swapon --show)"
  if [ -z "$checkswap" ]; then
    mkdir -v /var/cache/swap
    dd if=/dev/zero of=/var/cache/swap/swapfile bs=$v_swap_bs count=1M
    chmod 600 /var/cache/swap/swapfile
    mkswap /var/cache/swap/swapfile
    swapon /var/cache/swap/swapfile
    echo "/var/cache/swap/swapfile none swap sw 0 0" | tee -a /etc/fstab
  fi
}

function f_config_nano() {
  sudo -u $user cat <<EOT >> /home/$user/.nanorc
  set tabsize 2
  set tabstospaces
EOT
}

function f_disable_sudo_password_for_apt() {
  echo "$user ALL=(ALL) NOPASSWD: /usr/bin/apt-get" >> /etc/sudoers.d/tmpsudo$user
  chmod 0440 /etc/sudoers.d/tmpsudo$user
}

function f_enable_sudo_password_for_apt() {
  rm /etc/sudoers.d/tmpsudo$user
}

function f_install_sublimetext() {
  # Sublime Text
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
  echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
  apt-get update
  apt-get -y install sublime-text
}

function f_install_vncserver() {
  apt-get -y install vnc4server
  # Create vncserver launch file
  sudo -u $user touch /home/$user/vncserver.sh
  sudo -u $user chmod +x /home/$user/vncserver.sh
  if [ $v_vnc_localhost == true ]; then
    sudo -u $user echo "vncserver -geometry 1280x650 -localhost" > /home/$user/vncserver.sh
  else
    sudo -u $user echo "vncserver -geometry 1280x650" > /home/$user/vncserver.sh
  fi
}

function f_install_gui() {
  # Install xfce, vnc server, sublime-text
  apt-get update
  apt-get -y install xfce4 xfce4-goodies gnome-icon-theme
  f_install_sublimetext
  f_install_vncserver
  f_config_nano
}

function f_install_essential_packages() {
  apt-get -y update
  apt-get -y install dirmngr curl whois apt-transport-https unzip sudo
}

function f_install_apache() {
  apt-get -y install httpd
}

function f_add_domain() {
  read -p "Add a domain (y/n)? " add_domain
  printf "\n"
  if [ $add_domain == "y" ]; then
    read -p "Write your domain name: " domain_name
    printf "\n"
    mkdir /var/www/vhosts/$domain_name
    curl https://raw.githubusercontent.com/zldang/les/master/inc/nginx/custom_domain -o /etc/nginx/sites-available/$domain_name
    sed -i "s/domain_name/$domain_name/g" /etc/nginx/sites-available/$domain_name
    ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/$domain_name
  fi
}

function f_config_nginx() {
 
  rm /etc/nginx/nginx.conf
  rm /etc/nginx/conf.d/*
  
  mkdir /etc/nginx/sites-available
  mkdir /etc/nginx/sites-enabled
  
  curl https://raw.githubusercontent.com/zldang/les/master/inc/nginx/nginx_debian.conf -o /etc/nginx/nginx.conf
  curl https://raw.githubusercontent.com/zldang/les/master/inc/nginx/default -o /etc/nginx/sites-available/default
  ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
  mkdir -p /var/www/vhosts
  mv /usr/share/nginx/html /var/www/  
  rm -R /usr/share/nginx
  f_add_domain
  chown -R www-data:www-data /var/www

}

function f_install_nginx() {
  wget -qO - http://nginx.org/keys/nginx_signing.key | apt-key add -
  touch /etc/apt/sources.list.d/nginx.list
  cat <<EOT > /etc/apt/sources.list.d/nginx.list
    deb http://nginx.org/packages/$distro/ $distro_code nginx
    deb-src http://nginx.org/packages/$distro/ $distro_code nginx
EOT
  apt-get -y update  
  apt-get -y install nginx
  f_config_nginx
}


function f_install_php() {
  # PHP
  if [ $distro == "Debian" && $distro_code == "jessie" ]; then
    apt-get -y install php5-cli php5-fpm php5-mysqlnd php5-gd php5-mcrypt
  elif [ $distro == "Ubuntu" && $distro_code == "trusty" ]; then
    apt-get -y install php5-cli php5-fpm php5-mysqlnd php5-mbstring php5-gd php5-mcrypt
  elif [ $distro == "Ubuntu" && $distro_code == "bionic" ]; then
    apt-get -y install php-cli php-fpm php-mysql php-mbstring php-gd php-pear php-dev
    apt-get -y install libmcrypt-dev libreadline-dev
    printf "\n" | pecl install mcrypt-1.0.1
    bash -c "echo extension=mcrypt.so > /etc/php/7.2/fpm/conf.d/20-mcrypt.ini"
    bash -c "echo extension=mcrypt.so > /etc/php/7.2/cli/conf.d/20-mcrypt.ini"
  else
    apt-get -y install php-cli php-fpm php-mysql php-mbstring php-gd php-mcrypt
  fi
  chown -R www-data:www-data /var/lib/php/sessions
}

function f_install_openvpn() {
  wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
  mv /root/*.ovpn /home/$user/
  chown -R $user:$user /home/$user/
}

function f_install_mariadb() {
  apt-get -y install mariadb-server
}

function f_install_mysql() {
  apt-get -y install mysql-server
}

function f_secure_db() {
  sudo mysql -uroot << EOF
  UPDATE mysql.user SET Password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE User='root';
  DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
  DELETE FROM mysql.user WHERE user='';
  DROP DATABASE IF EXISTS test;
  UPDATE mysql.user SET plugin='' WHERE user='root';
  FLUSH PRIVILEGES;
EOF
}

function f_install_firewall() {
  if [ $v_firewall == "ufw" ]; then
    apt-get -y install ufw
    for i in "${v_portslist[@]}"
    do
      :
      echo "Added port $i to firewall ports open list"; ufw allow $i/tcp &> /dev/null
      done
    ufw reload
    ufw --force enable
  fi

  if [ $v_firewall == "firewalld" ]; then
    apt-get -y install firewalld
    for i in "${v_portslist[@]}"
    do
      :
      echo "Added port $i to firewall ports open list"; firewall-cmd --zone=public --permanent --add-port=$i/tcp &> /dev/null
      done
    firewall-cmd --zone=public --remove-service=ssh --permanent
    firewall-cmd --reload
    service firewalld restart
  fi
}

function f_postinstall() {
  apt-get -y update
  apt-get -y upgrade
  apt-get -y dist-upgrade
  apt-get -y autoremove
  apt-get -y autoclean
}
