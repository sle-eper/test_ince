#!/bin/sh
set -e

DOMAIN_NAME="${DOMAIN_NAME:-sleeper.42.fr}"

# Create SSL directory if needed
mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=MA/ST=Benguerir/L=Benguerir/O=42/OU=1337/CN=${DOMAIN_NAME}"
fi

echo "Configuring nginx for domain: ${DOMAIN_NAME}"

# Render nginx.conf from template
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Validate nginx config
nginx -t

# Start nginx in foreground
exec nginx -g "daemon off;"