#!/bin/bash

# Ubuntu
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install python-certbot-nginx 
sudo apt-get install python3-pip python3-dev
sudo pip3 install pyasn1 setuptools wheel pyyaml
sudo pip3 install certbot-dns-cloudflare

domain_name=''

sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /home/$user/cloudflare.ini \
  --register-unsafely-without-email \
  -d $domain_name \
  -d www.$domain_name
  
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
