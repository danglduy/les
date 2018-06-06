# Description
Linux Environment Setup for Debian 9 and Ubuntu 16.04/18.04.

This script will:
- Install LAMP/LEMP: Apache/Nginx + MariaDB + PHP-FPM
- Install GUI (XFCE), VNC Server and Sublime Text (not enabled by default)
- Disable root ssh access
- Disable ssh password authentication
- Create one user with sudo

This script is under development and not ready for production use. Use at your own risk!

# Install
```Shell
#Get the script
wget https://raw.githubusercontent.com/zldang/les/master/les.sh

#Change variables for your environment
nano les.sh 

#Add run permission
chmod +x les.sh

#Run
./les.sh
```
