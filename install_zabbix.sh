#!/bin/bash

# Zabbix 一键安装脚本 (Ubuntu 22.04)
# 作者: 你的名字
# GitHub: https://github.com/你的用户名/你的仓库

set -e

echo "更新系统..."
sudo apt update && sudo apt upgrade -y

echo "安装依赖..."
sudo apt install -y wget curl gnupg2 software-properties-common lsb-release

echo "添加 Zabbix 官方仓库..."
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu$(lsb_release -rs)_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu$(lsb_release -rs)_all.deb
sudo apt update

echo "安装 Zabbix Server + Frontend + Agent + MySQL"
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server

echo "配置数据库..."
DB_ROOT_PASS="root123"        # 你可以修改
DB_ZABBIX="zabbix"
DB_USER="zabbix"
DB_PASS="zabbix123"

sudo mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_ROOT_PASS';
CREATE DATABASE $DB_ZABBIX CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_ZABBIX.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "导入初始数据库..."
sudo zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u$DB_USER -p$DB_PASS $DB_ZABBIX

echo "配置 Zabbix Server 数据库连接..."
sudo sed -i "s/# DBPassword=/DBPassword=$DB_PASS/" /etc/zabbix/zabbix_server.conf

echo "启动并启用服务..."
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "安装完成！"
IP=$(hostname -I | awk '{print $1}')
echo "请在浏览器访问：http://$IP/zabbix"
echo "默认 Zabbix 登录: Admin / zabbix"

