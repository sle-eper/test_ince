FROM alpine:3.18

RUN apk add --no-cache nginx openssl envsubst

RUN mkdir -p /var/www/html /run/nginx /etc/nginx/ssl

# Copy template config
COPY conf/nginx.conf /etc/nginx/nginx.conf.template

# SSL setup / entrypoint script
COPY tools/ssl_setup.sh /usr/local/bin/ssl_setup.sh
RUN chmod +x /usr/local/bin/ssl_setup.sh

EXPOSE 443
 
CMD ["/usr/local/bin/ssl_setup.sh"]