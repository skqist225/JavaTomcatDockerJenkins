# adding repository and installing nginx
apt update
apt install nginx -y
cat <<EOT>> airtntapp
upstream airtntapp {
 server airtntApp:8080;
}

server {
  listen 80;
location / {
  proxy_pass http://airtntapp;
}
}

EOT

mv airtntapp /etc/nginx/sites-available/airtntapp
rm -rf /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/airtntapp /etc/nginx/sites-enabled/airtntapp

#starting nginx service and firewall
systemctl start nginx
systemctl enable nginx
systemctl restart nginx