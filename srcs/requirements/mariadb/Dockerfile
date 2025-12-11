FROM debian:11

RUN apt update && apt install -y mariadb-server \
 && mkdir -p /var/run/mysqld \
 && chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# Override default bind-address by using a high-priority custom config
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf

EXPOSE 3306

# Use our init script to initialize and then start MariaDB
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh
CMD ["/usr/local/bin/init.sh"]
