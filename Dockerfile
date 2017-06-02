# iRedmail Dockerfile in CentOS 7
#
# Build:
# docker build -t burkeazbill/iredmail:latest .
#
# Create:
# docker create --privileged -it --restart=always -v /srv/iredmail/vmail:var/vmail -p 80:80 -p 443:443 -p 25:25 -p 587:587 -p 110:110 -p 143:143 -p 993:993 -p 995:995 -h your_domain.com --name container_name burkeazbill/iredmail
#
# Start:
# docker start container_name
#
# Connect bash:
# docker exec -it container_name bash

# Pull base image
FROM centos:latest

# Maintainer
MAINTAINER Burke Azbill <dimensionquest@gmail.com>

# Env
ENV IREDMAIL_VERSION 0.9.6
ENV container docker
ENV HOME /root
WORKDIR /root

# Install packages necessary:
RUN yum install -y deltarpm; \
    yum update -y; \
    yum install -y unzip wget curl git tar bzip2 hostname rsyslog openssl epel-release; \
    yum -y reinstall systemd; \
    yum clean all

# Get iredmail, extract and remove tar
RUN mkdir -p /opt/iredmail; \
    cd /opt/iredmail; \
    wget -c https://bitbucket.org/zhb/iredmail/downloads/iRedMail-$IREDMAIL_VERSION.tar.bz2; \
    tar xjf iRedMail-$IREDMAIL_VERSION.tar.bz2; \
    rm iRedMail-$IREDMAIL_VERSION.tar.bz2

# Install systemd
# RUN yum -y reinstall systemd; yum clean all; \
RUN  (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
     rm -f /lib/systemd/system/multi-user.target.wants/*;\
     rm -f /etc/systemd/system/*.wants/*;\
     rm -f /lib/systemd/system/local-fs.target.wants/*; \
     rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
     rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
     rm -f /lib/systemd/system/basic.target.wants/*;\
     rm -f /lib/systemd/system/anaconda.target.wants/*;

# Copy script and config files
ADD iredmail/config.iredmail /opt/iredmail/
ADD iredmail/iredmail.sh /opt/iredmail/iredmail.sh
ADD iredmail.cfg /opt/iredmail/iredmail.cfg
ADD iredmail/create_mail_domain_SQL.sh /opt/iredmail/create_mail_domain_SQL.sh
ADD iredmail/iredmail-install.service /etc/systemd/system/iredmail-install.service

RUN chmod +x /opt/iredmail/iredmail.sh
RUN ln -s /etc/systemd/system/iredmail-install.service /etc/systemd/system/multi-user.target.wants/iredmail-service.service

# Set volume for systemd
VOLUME [ "/sys/fs/cgroup" ]

# Open Ports:
# Apache: 80/tcp, 443/tcp Postfix: 25/tcp, 587/tcp
# Dovecot: 110/tcp, 143/tcp, 993/tcp, 995/tcp
EXPOSE 80 443 25 587 110 143 993 995

# iredmail directory
WORKDIR /opt/iredmail

# Run systemd
CMD ["/usr/sbin/init"]
