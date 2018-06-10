#!/bin/bash
# This script is for setting up Debian/Ubuntu Server.

### SET VARIABLES

# Disable password login? If true, password login via SSH will be disabled. Option: true/false
v_disable_ssh_password=true

# Create ~/.ssh/authorized_keys . Option: true/false
v_create_ssh_key=true

# Disable root login through SSH? Option: true/false
v_disable_root_ssh_login=true

# Set public key, replace with your own from puttygen/ssh-keygen.
# You can leave blank f you already set keys during setup the droplet (Digital Ocean/Vultr), or your $passwordlogin == false
# For Linode/normal user: Define this or you need to specify your own in ~/.ssh/authorized_keys
# BE CAREFUL: If $passwordlogin == false, $publickey == '', you don't setup your droplet with any keys \
# and you don't define your public key in ~/.ssh/authorized_keys, you WILL be blocked from SSH Login.
v_public_key=''

# Swap block size? 512 => 512MB swap, 1024 => 1GB swap.
v_swap_bs=512

# Do you use GUI? If yes we install GUI tools: XFCE, VNC, Sublime Text. Option: true/false
v_install_gui=false

# Access VNC from localhost only (only if $guiinstall == true). Option: true/false
v_vnc_localhost=true

# Install PHP? Option: true/false
v_install_php=false

# Install MariaDB/Mysql Database? Option: true/false
v_install_mdb=false

# Install mysql for ubuntu instead of mariadb. Option: true/false
v_install_mysql_ubuntu=false

# Install web server? Option: true/false
v_install_http_srv=false

# Install Nginx or Apache? You can only choose between nginx or apache. This script doesn't support nginx as reverse proxy. Option: "nginx"/"apache"
v_http_srv="nginx"

# Install Firewall? Option: true/false
v_install_firewall=true

# Firewall option? Option: "ufw"/"firewalld"
v_firewall="ufw"

# Ports for opening. Default 22. Add your ports. By default if install http server we open 80 and 443 port.
v_portslist=(22)

# Install Openvpn (Thanks to Nyr/openvpn-install) ? Option: true/false
v_install_openvpn=false

### END OF SETTING VARIABLES SECTION

distro="$(lsb_release -i -s)"
distro="${distro,,}"
distro_code="$(lsb_release -c -s)"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
#
source <(curl -s https://raw.githubusercontent.com/zldang/les/master/inc/functions.sh)
source <(curl -s https://raw.githubusercontent.com/zldang/les/master/inc/install.sh)


