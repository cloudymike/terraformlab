#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install awscli
apt-get -y install nginx
apt-get install -y software-properties-common
add-apt-repository -y universe
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get install -y certbot python-certbot-nginx
apt-get install -y git
apt-get install -y python3-pip

# This should not be needed when working with AWS mqtt
apt-get install -y mosquitto mosquitto-clients




if [ "${release_type}" == "production"]; then
  echo certbot --nginx -n --agree-tos\
    -d "${subdomain}.${domain}"\
    -m "admin@${domain}"
else
  certbot --nginx -n --agree-tos\
    -d "${subdomain}.${domain}"\
    -m "admin@${domain}" --test-cert
fi


aws s3 cp s3://hopfront/nginx_default.conf /etc/nginx/sites-enabled/default
service nginx restart

git clone -q --depth 1 https://github.com/cloudymike/hopitty.git
cd hopitty/src/hopfront
pip3 install -r requirements.txt

cat > /hopfrontenv.sh << EOF
export FN_AUTH_REDIRECT_URI=https://${subdomain}.${domain}/google/auth
export FN_BASE_URI=https://${subdomain}.${domain}
export FLASK_DEBUG=0
export FN_FLASK_SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
EOF
aws s3 cp s3://hopfront/googauth.sh /googauth.sh

source /hopfrontenv.sh
source /googauth.sh
nohup python3 ./web.py -m &
