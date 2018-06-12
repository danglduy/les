#!/bin/bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /home/$user/cloudflare.ini \
  -d domain_name \
  -d www.domain_name
