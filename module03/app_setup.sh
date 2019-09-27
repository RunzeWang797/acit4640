#!/bin/bash

useradd -m "admin" -p "P@ssw0rd";

usermod -a -G wheel admin;

cat files/acit_admin_id_rsa.pub >> /home/admin/.ssh/authorized_keys;

chown admin:admin ~admin/.ssh/authorized_keys;

chmod 600 ~admin/.ssh/authorized_keys;


sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers;

yum install epel-release vim git tcpdump curl net-tools bzip2 -y;
yum update -y;

#iptables -A INPUT -p tcp -m tcp -m multiport ! --dports 22,80,443 -j DROP;

firewall-cmd --zone=public --add-service=http;
firewall-cmd --zone=public --add-service=ssh;
firewall-cmd --zone=public --add-service=https;

sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config;

useradd -m -r todo-app && passwd -l todo-app;

yum install nodejs npm -y;

yum install mongodb-server -y;

systemctl enable mongod && systemctl start mongod;

su - todo-app <<ABCD

mkdir app;

cd app

git clone https://github.com/timoguic/ACIT4640-todo-app.git .;

npm install;

sed -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js;

ABCD

cd /home/todo-app/app;

yum install nginx;

systemctl enable nginx;

sed -i 's/\/usr\/share\/nginx\/html/\/home\/todo-app\/app\/public/g' /etc/nginx/nginx.conf;

sed -i 's/server { $/server { index index.html; location \/api\/todos { proxy_pass http:\/\/localhost:8080; }/' /etc/nginx/nginx.conf;

yum install jq;

echo Checking locally:

curl -s localhost/api/todos | jq;

echo startserver

cd /lib/systemd/system;

echo "[Unit]
Description=Todo app, ACIT4640
After=network.target

[Service]
Environment=NODE_PORT=8080
WorkingDirectory=/home/todo-app/app
Type=simple
User=todo-app
ExecStart=/usr/bin/node /home/todo-app/app/server.js
Restart=always

[Install]
WantedBy=multi-user.target" > todoapp.service;

systemctl daemon-reload;

systemctl enable todoapp;

systemctl start todoapp;

echo Checking if Todo-app is running:

systemctl status todoapp;

cd /home/todo-app/app;

chmod 755 /home/todo-app;
