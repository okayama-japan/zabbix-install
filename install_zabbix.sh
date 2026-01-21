#!/bin/bash

# =========================================
# 一键安装 Zabbix 6.4 (Server + Web + Agent)
# 适用于 Ubuntu 20.04 / 22.04
# =========================================

# 配置项
DB_PASS="Zabbix123!"   # 数据库密码，可修改
ZABBIX_VERSION="6.4"
UBUNTU_VERSION=$(lsb_release -rs)

echo "=== 更新系统 ==="
apt update && apt upgrade -y

echo "=== 安装必要软件 ==="
apt install wget curl gnupg2 software-properties-common lsb-release unzip -y

echo "=== 安装 MariaDB ==="
apt install mariadb-server mariadb-client -y
systemctl enable --now mariadb

echo "=== 创建 Zabbix 数据库和用户 ==="
mysql -e "CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "=== 导入 Zabbix 官方仓库 ==="
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu${UBUNTU_VERSION}_all.deb
dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu${UBUNTU_VERSION}_all.deb
apt update

echo "=== 安装 Zabbix Server + Web + Agent ==="
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent -y

echo "=== 导入初始数据库 ==="
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -p"$DB_PASS" zabbix

echo "=== 配置 Zabbix Server ==="
sed -i "s/# DBPassword=/DBPassword=$DB_PASS/" /etc/zabbix/zabbix_server.conf

echo "=== 启动服务 ==="
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

echo "=== 配置防火墙 ==="
ufw allow 80/tcp
ufw allow 10050/tcp
ufw allow 10051/tcp
ufw reload

echo "=== 安装完成！ ==="
echo "请在浏览器访问：http://$(curl -s ifconfig.me)/zabbix"
echo "默认账号：admin"
echo "默认密码：zabbix"
