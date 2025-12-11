#!/bin/sh
set -e

# Ensure data and runtime directories exist and have correct ownership
mkdir -p /var/lib/mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Load passwords from Docker secrets if present, otherwise fall back to env vars
if [ -f /run/secrets/db_root_password ]; then
	DB_ROOT_PWD="$(cat /run/secrets/db_root_password)"
else
	DB_ROOT_PWD="${DB_ROOT_PWD:-}"
fi

if [ -f /run/secrets/db_password ]; then
	DB_USER_PWD="$(cat /run/secrets/db_password)"
else
	DB_USER_PWD="${DB_USER_PWD:-}"
fi

if [ -f /run/secrets/credentials ]; then
	WP_ADMIN_PWD="$(cat /run/secrets/credentials)"
else
	WP_ADMIN_PWD="${WP_ADMIN_PWD:-}"
fi

echo "Init script: checking MariaDB data directory..."

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Database directory empty — initializing MariaDB data files..."
	mariadbd --initialize-insecure --user=mysql --datadir=/var/lib/mysql || true
fi

echo "Bootstrapping SQL (ensuring database and users exist)..."
mariadbd --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \
	\`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_USER_PWD}';
GRANT ALL PRIVILEGES ON \
	\`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

CREATE USER IF NOT EXISTS '${WP_ADMIN_USER}'@'%' IDENTIFIED BY '${WP_ADMIN_PWD}';
GRANT ALL PRIVILEGES ON \
	\`${MYSQL_DATABASE}\`.* TO '${WP_ADMIN_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PWD}';

FLUSH PRIVILEGES;
EOF

echo "MariaDB bootstrap complete."

echo "Starting MariaDB server..."
exec mysqld --user=mysql
