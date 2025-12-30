FROM alpine:3.18

# Install PHP-FPM, PHP extensions, tools, and wp-cli deps
RUN apk add --no-cache \
    php81 \
    php81-fpm \
    php81-mysqli \
    php81-json \
    php81-mbstring \
    php81-xml \
    php81-gd \
    php81-curl \
    php81-zip \
    php81-phar \
    php81-tokenizer \
    curl \
    tar \
    wget \
    bash \
    su-exec \
    shadow \
    mariadb-client \
    netcat-openbsd

# Create wordpress user + web root
RUN adduser -D -s /bin/sh wordpress \
    && mkdir -p /var/www/html \
    && chown -R wordpress:wordpress /var/www

WORKDIR /var/www/html

# Download WordPress
RUN wget https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz --strip-components=1 \
    && rm latest.tar.gz \
    && chown -R wordpress:wordpress /var/www/html

# Install wp-cli
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# PHP-FPM listen on 0.0.0.0:9000 for nginx/fastcgi
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php81/php-fpm.d/www.conf \
    && sed -i 's|^user = .*|user = wordpress|' /etc/php81/php-fpm.d/www.conf \
    && sed -i 's|^group = .*|group = wordpress|' /etc/php81/php-fpm.d/www.conf

COPY tools/configure.sh /usr/local/bin/configure.sh
RUN chmod +x /usr/local/bin/configure.sh

EXPOSE 9000

CMD ["/usr/local/bin/configure.sh"]