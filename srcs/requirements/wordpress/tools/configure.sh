#!/bin/sh
set -e

# Read passwords from Docker secrets if present
if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
fi
if [ -f /run/secrets/admin_password ]; then
    WP_ADMIN_PASSWORD="$(cat /run/secrets/admin_password)"
fi

WP_USER_PASSWORD="${WP_USER_PASSWORD:-defaultuserpass123}"

echo "Waiting for MariaDB..."
while ! nc -z mariadb 3306; do
    sleep 1
done
echo "MariaDB is ready!"

cd /var/www/html
chown -R wordpress:wordpress /var/www/html

if [ ! -f wp-config.php ]; then
    echo "Creating WordPress configuration..."

    su -s /bin/sh wordpress -c "wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb:3306 \
        --skip-check"

    if ! su -s /bin/sh wordpress -c "wp core is-installed"; then
        echo "Installing WordPress..."
        su -s /bin/sh wordpress -c "wp core install \
            --url=${WP_URL} \
            --title='${WP_TITLE}' \
            --admin_user=${WP_ADMIN_USER} \
            --admin_password=${WP_ADMIN_PASSWORD} \
            --admin_email=${WP_ADMIN_EMAIL}"

        su -s /bin/sh wordpress -c "wp user create ${WP_USER} ${WP_USER_EMAIL} \
            --user_pass=${WP_USER_PASSWORD} \
            --role=author"
        echo "WordPress installation completed!"
    fi
else
    echo "wp-config.php already exists, skipping install."
fi

# echo "Starting PHP built-in server on :8080..."
# exec php -S 0.0.0.0:8080 -t /var/www/html

echo "Starting php-fpm81..."
exec php-fpm81 -F