#!/bin/bash

# Zabbix 一键安装脚本 (Ubuntu 22.04)
# 支持自定义 Zabbix 版本和数据库密码
# 作者: 你的名字
# GitHub: https://github.com/你的用户名/你的仓库

set -e

# -------------------------
# 用户可配置参数
# -------------------------
ZABBIX_VERSION="6.4"
DB_ROOT_PASS="root123"        # MySQL root 密码
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASS="zabbix123"
APACHE_PORT=80
# -------------------------

# 检查是否以 root 或 sudo 运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 或 sudo 运行此脚本"
  exit 1
fi

echo "更新系统..."
apt update && apt upgrade -y

echo "安装依赖..."
apt install -y wget curl gnupg2 software-properties-common lsb-release ufw

# -------------------------
# 安装 Zabbix 官方仓库
# -------------------------
echo "添加 Zabbix 官方仓库..."
wget https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VERSION}-1+ubuntu$(lsb_release -rs)_all.deb
dpkg -i zabbix-release_${ZABBIX_VERSION}-1+ubuntu$(lsb_release -rs)_all.deb
apt update

# -------------------------
# 安装 Zabbix + MySQL
# -------------------------
echo "安装 Zabbix Server + Frontend + Agent + MySQL"
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server

# -------------------------
# 配置数据库
# -------------------------
echo "配置 MySQL 数据库..."
mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "导入 Zabbix 初始数据库..."
zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME}

# -------------------------
# 配置 Zabbix Server
# -------------------------
echo "配置 Zabbix Server 数据库连接..."
sed -i "s/# DBPassword=/DBPassword=${DB_PASS}/" /etc/zabbix/zabbix_server.conf

# -------------------------
# 启动服务
# -------------------------
echo "启动 Zabbix 服务..."
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

# -------------------------
# 配置防火墙
# -------------------------
echo "配置防火墙 (ufw)..."
ufw allow ${APACHE_PORT}/tcp
ufw allow 10050/tcp
ufw allow 10051/tcp
ufw --force enable

# -------------------------
# 完成
# -------------------------
IP=$(hostname -I | awk '{print $1}')
echo "---------------------------------------------"
echo "Zabbix 安装完成！"
echo "请在浏览器访问：http://${IP}/zabbix"
echo "默认登录: Admin / zabbix"
echo "数据库: ${DB_NAME}, 用户: ${DB_USER}, 密码: ${DB_PASS}"
echo "---------------------------------------------"
