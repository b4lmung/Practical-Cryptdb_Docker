FROM ubuntu:16.04

MAINTAINER agribu

# make sure the package repository is up to date
RUN apt-get update

# Install stuff
RUN apt-get install -y ca-certificates supervisor sudo ruby git vim less net-tools

RUN mkdir -p /var/log/supervisor

RUN echo 'root:root' |chpasswd

# Set Password of MySQL root
ENV MYSQL_PASSWORD mysql

# Install MySQL Server in a Non-Interactive mode. Default root password will be $MYSQL_PASSWORD
RUN echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server

RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf 

RUN /usr/sbin/mysqld & sleep 10s && echo "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY 'mysql' WITH GRANT OPTION; FLUSH PRIVILEGES"

# Clone project repository
RUN git clone https://github.com/b4lmung/cryptdb.git /opt/cryptdb
WORKDIR /opt/cryptdb

# Adding debian compatibility to apt syntax
RUN sed -i 's/apt /apt-get /g' INSTALL.sh

# Setup
RUN ./INSTALL.sh

RUN echo "\
[supervisord]\n\
nodaemon=true\n\
\n\
[program:mysql]\n\
command=service mysql start\n\
\n\
" > /etc/supervisor/conf.d/supervisord.conf

ENV TERM xterm

CMD ["/usr/bin/supervisord"]

EXPOSE 22 3306 3399
