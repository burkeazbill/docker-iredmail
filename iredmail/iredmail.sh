#!/bin/bash
SECONDS=0
. /opt/iredmail/iredmail.cfg

## files
CONFIG_FILE_TMP=/opt/iredmail/config.iredmail
CONFIG_FILE_IRE=/opt/iredmail/iRedMail-$IREDMAIL_VERSION/config
PASSWD_GENERATOR=$(openssl rand -base64 16)
LOGFILE=/var/vmail/iredmail-install.log
echo "Logging started, additional config info found in /opt/iredmail/ " > $LOGFILE
echo "Domain set to: $DOMAIN" >> $LOGFILE
echo "Disable Mail Scanners set to: $DISABLE_SCANNERS" >> $LOGFILE
echo "Disable SSL Redirect set to: $DISABLE_SSL_REDIRECT" >> $LOGFILE
echo "Additional Domains: $ADDL_DOMAINS" >> $LOGFILE
echo "Primary Domain Users: $PRIMARY_DOMAIN_USERS" >> $LOGFILE

replace_iredmail() {
  
  echo '\n\n' >> $LOGFILE
  echo "================================================================================" >> $LOGFILE
  echo '\n' >> $LOGFILE
  echo "Starting replace_iredmail function..." >> $LOGFILE
  # Replace first domain in hosts file
  # sed -i "s/localhost/mail.$DOMAIN   mail     localhost /g" /etc/hosts >> $LOGFILE
  echo -e "127.0.0.1   mail.$DOMAIN   mail     localhost \n" > /etc/hosts
  echo -e "::1         mail.$DOMAIN   mail     localhost \n" >> /etc/hosts
  # sed -i "s/::1     localhost ip6-localhost ip6-loopback/::1     mail.$DOMAIN   mail     localhost ip6-localhost ip6-loopback /g" /etc/hosts
  echo "Updated hosts file:" >> $LOGFILE
  cat /etc/hosts  >> $LOGFILE

  # Replace nameserver
  echo -e "nameserver $DNS1 \n" > /etc/resolv.conf
  # If more than one DNS server available, comment the line above and use this format:
  # echo -e "nameserver $DNS1 \nnameserver $DNS2 \n" > /etc/resolv.conf
  echo "Updated resolv.conf file:" >> $LOGFILE
  cat /etc/resolv.conf  >> $LOGFILE

  # copy config iredmail file
  mv $CONFIG_FILE_TMP $CONFIG_FILE_IRE
  # replace password
  sed -i "s/MYSQL_ROOT_PASSWD=.*/MYSQL_ROOT_PASSWD='$PASSWD'/g" $CONFIG_FILE_IRE
  sed -i "s/DOMAIN_ADMIN_PASSWD_PLAIN=.*/DOMAIN_ADMIN_PASSWD_PLAIN='$PASSWD'/g" $CONFIG_FILE_IRE
  sed -i "s/DOMAIN_ADMIN_PASSWD=.*/DOMAIN_ADMIN_PASSWD='$PASSWD'/g" $CONFIG_FILE_IRE
  sed -i "s/SITE_ADMIN_PASSWD=.*/SITE_ADMIN_PASSWD='$PASSWD'/g" $CONFIG_FILE_IRE
  sed -i "s/FIRST_USER_PASSWD=.*/FIRST_USER_PASSWD='$PASSWD'/g" $CONFIG_FILE_IRE
  sed -i "s/FIRST_USER_PASSWD_PLAIN=.*/FIRST_USER_PASSWD_PLAIN='$PASSWD'/g" $CONFIG_FILE_IRE
  # replace domain
  sed -i "s/FIRST_DOMAIN=.*/FIRST_DOMAIN='$DOMAIN'/g" $CONFIG_FILE_IRE
  sed -i "s/SITE_ADMIN_NAME='postmaster@.*/SITE_ADMIN_NAME='postmaster@$DOMAIN'/g" $CONFIG_FILE_IRE
  # password generator
  sed -i "s/VMAIL_DB_BIND_PASSWD=.*/VMAIL_DB_BIND_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/VMAIL_DB_ADMIN_PASSWD=.*/VMAIL_DB_ADMIN_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/LDAP_BINDPW=.*/LDAP_BINDPW='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/LDAP_ADMIN_PW=.*/LDAP_ADMIN_PW='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/AMAVISD_DB_PASSWD=.*/AMAVISD_DB_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/CLUEBRINGER_DB_PASSWD=.*/CLUEBRINGER_DB_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/IREDADMIN_DB_PASSWD=.*/IREDADMIN_DB_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/RCM_DB_PASSWD=.*/RCM_DB_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/SOGO_DB_PASSWD=.*/SOGO_DB_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  sed -i "s/SOGO_SIEVE_MASTER_PASSWD=.*/SOGO_SIEVE_MASTER_PASSWD='$PASSWD_GENERATOR'/g" $CONFIG_FILE_IRE
  # Disable NTP Pools
  if [ "$NTPSERVER" ]; then
    echo " Setting custom NTP Server: $NTPSERVER" >> $LOGFILE
    sed -i '/iburst/s/^/# /' /etc/ntp.conf
    sed -i '/server 3/aserver $NTPSERVER iburst' /etc/ntp.conf
    systemctl enable ntpd
    systemctl restart ntpd
    /usr/sbin/ntpq -p >> $LOGFILE
  fi
  if [ "$DISABLE_SCANNERS" == "true" ]; then
    echo "Replace section: disabling mail scanners" >> $LOGFILE
    sed -i '/clamav/s/^/# /' /opt/iredmail/iRedMail-$IREDMAIL_VERSION/iRedMail.sh
    sed -i '/amavisd/s/^/# /' /opt/iredmail/iRedMail-$IREDMAIL_VERSION/iRedMail.sh
    sed -i '/sa_config/s/^/# /' /opt/iredmail/iRedMail-$IREDMAIL_VERSION/iRedMail.sh
    sed -i '/spamassassin/s/^/# /' /opt/iredmail/iRedMail-$IREDMAIL_VERSION/iRedMail.sh
  fi
  echo " Completed replace_iredmail function..." >> $LOGFILE

}

# install iredmail
install_iredmail() {

  echo " Starting install_iredmail function..." >> $LOGFILE
  IREDMAIL_DEBUG='NO' \
  AUTO_USE_EXISTING_CONFIG_FILE=y \
  AUTO_INSTALL_WITHOUT_CONFIRM=y \
  AUTO_CLEANUP_REMOVE_SENDMAIL=y \
  AUTO_CLEANUP_REMOVE_MOD_PYTHON=y \
  AUTO_CLEANUP_REPLACE_FIREWALL_RULES=n \
  AUTO_CLEANUP_RESTART_IPTABLES=y \
  AUTO_CLEANUP_REPLACE_MYSQL_CONFIG=y \
  AUTO_CLEANUP_RESTART_POSTFIX=n \
  bash /opt/iredmail/iRedMail-$IREDMAIL_VERSION/iRedMail.sh >> $LOGFILE
  echo " Completed install_iredmail function..." >> $LOGFILE

}

# post-install config edits - allows to override defaults
post_install_iredmail(){

  echo "Running post_install_iredmail" >> $LOGFILE
  echo "Checking SSL Redirect: $DISABLE_SSL_REDIRECT" >> $LOGFILE
  if [ "$DISABLE_SSL_REDIRECT" == "true" ]; then
    # Disable SSL Redirect for Roundcube mail
    echo "Disabling Roundcube SSL redirect..." >> $LOGFILE
    sed -i "s/force_https'] = .*/force_https'] = false; /" /var/www/roundcubemail-1.2.0/config/config.inc.php
    echo "Disabling iRedAdmin SSL redirect..." >> $LOGFILE
    rm -f /etc/nginx/sites-conf.d/default/1-include-tmpl-redirect-to-https.conf
    cp /etc/nginx/sites-conf.d/default-ssl/*iredadmin.conf /etc/nginx/sites-conf.d/default/
    cp /etc/nginx/sites-conf.d/default-ssl/*roundcube.conf /etc/nginx/sites-conf.d/default/
    systemctl restart nginx
    # OLD Method
    #sed -i '/redirect_to_https.tmpl;/s/^/# /' /etc/nginx/conf.d/00-default.conf
    #line=$(sed -n '/php-catchall.tmpl/=' /etc/nginx/conf.d/00-default.conf);
    #line=$(echo $line | cut -d " " -f 1)
    #sed -i "${line} i \    #Web applications.\n    include /etc/nginx/templates/roundcube.tmpl;\n    include /etc/nginx/templates/iredadmin.tmpl;\n    include /etc/nginx/templates/sogo.tmpl;" /etc/nginx/conf.d/00-default.conf
  fi
  if [ "$DISABLE_SCANNERS" == "true" ]; then
    echo "Disabling content filters in main.cf and master.cf" >> $LOGFILE
    sed -i '/content_filter/s/^/# /' /etc/postfix/main.cf
    sed -i '/smtp-amavis/s/^/# /' /etc/postfix/master.cf
    sed -i '/smtp_data/s/^/# /' /etc/postfix/master.cf
    sed -i '/smtp_send/s/^/# /' /etc/postfix/master.cf
    sed -i '/disable_dns/s/^/# /' /etc/postfix/master.cf
    sed -i '/max_use/s/^/# /' /etc/postfix/master.cf
  fi
  echo "Relaxing mail sending restrictions in /etc/postfix/helo_access.pcre" >> $LOGFILE
  sed -i '/(\\.local)/s/^/# /' /etc/postfix/helo_access.pcre
  echo "Updating to allow for plaintext authentication" >> $LOGFILE
  sed -i "s/disable_plaintext_auth = yes/disable_plaintext_auth = no/g" /etc/dovecot/dovecot.conf
  sed -i "s/ssl = required/ssl = yes/g" /etc/dovecot/dovecot.conf
  echo "Exiting post_install_iredmail" >> $LOGFILE

}

# Check if config file exists
iredmail() {

  echo " Starting mail iredmail function..." >> $LOGFILE
  echo "Checking configs..." >> $LOGFILE
  #check config file
  if [ ! -f /opt/iredmail/iRedMail-$IREDMAIL_VERSION/config ]; then
      replace_iredmail
      install_iredmail
      post_install_iredmail
      # enable services
      echo "Enabling services..." >> $LOGFILE
      /usr/bin/systemctl enable mariadb.service
      /usr/bin/systemctl enable postfix.service
      /usr/bin/systemctl enable dovecot.service
      /usr/bin/systemctl enable nginx.service
      /usr/bin/systemctl enable php-fpm.service
      /usr/bin/systemctl enable iredapd.service
      if [ "$DISABLE_SCANNERS" == "true" ]; then
        echo "Disabling clamd and amavisd..." >> $LOGFILE
        /usr/bin/systemctl disable clamd@amavisd.service
        /usr/bin/systemctl disable amavisd.service
      else
        echo "Enabling clamd and amavisd..." >> $LOGFILE
        /usr/bin/systemctl enable clamd@amavisd.service
        /usr/bin/systemctl enable amavisd.service
      fi
      #/usr/bin/systemctl enable cbpolicyd.service
      #/usr/bin/systemctl enable uwsgi.service
      /usr/bin/systemctl enable rsyslog.service
      /usr/bin/systemctl enable crond.service
      # run services
      echo "Starting services..." >> $LOGFILE
      /usr/bin/systemctl start mariadb.service
      /usr/bin/systemctl start postfix.service
      /usr/bin/systemctl start dovecot.service
      #/usr/bin/systemctl start nginx.service
      #/usr/bin/systemctl start php-fpm.service
      /usr/bin/systemctl start iredapd.service
      #/usr/bin/systemctl start cbpolicyd.service
      if [ "$DISABLE_SCANNERS" == "true" ]; then
        echo "Stopping clamd and amavisd..." >> $LOGFILE
        /usr/bin/systemctl stop clamd@amavisd.service
        /usr/bin/systemctl stop amavisd.service
      else
        echo "Starting clamd and amavisd..." >> $LOGFILE
        /usr/bin/systemctl start clamd@amavisd.service
        /usr/bin/systemctl start amavisd.service
      fi
      #/usr/bin/systemctl start uwsgi.service
      /usr/bin/systemctl start rsyslog.service
      /usr/bin/systemctl start crond.service
      echo "Services Started!" >> $LOGFILE
      echo "Adding domains: $ADDL_DOMAINS" >> $LOGFILE
      cd /opt/iredmail
      /bin/bash /opt/iredmail/create_mail_domain_SQL.sh $ADDL_DOMAINS
      /usr/bin/mysql -uroot -p$PASSWD vmail < /opt/iredmail/domains.sql
      echo "Adding users to rainpole.com" >> $LOGFILE
      sed -i "s/DEFAULT_PASSWD=.*/DEFAULT_PASSWD="$PASSWD" /" /opt/iredmail/iRedMail-$IREDMAIL_VERSION/tools/create_mail_user_SQL.sh
      sed -i "s/USE_DEFAULT_PASSWD=.*/USE_DEFAULT_PASSWD='YES' /" /opt/iredmail/iRedMail-$IREDMAIL_VERSION/tools/create_mail_user_SQL.sh
      cd /opt/iredmail/iRedMail-$IREDMAIL_VERSION/tools
      /bin/bash create_mail_user_SQL.sh $DOMAIN $PRIMARY_DOMAIN_USERS
      /usr/bin/mysql -uroot -p$PASSWD vmail < /opt/iredmail/iRedMail-$IREDMAIL_VERSION/tools/output.sql
      duration=$SECONDS
      echo "$(($duration /60)) minutes and $(($duration % 60)) seconds for install/config to complete." >> $LOGFILE
      echo "Exiting iredmail function..." >> $LOGFILE
      # remove iredmail install script
      /usr/bin/systemctl disable iredmail-install.service
  fi
  echo " Completed mail iredmail function..." >> $LOGFILE

}
# Install iRedmail
echo "Starting iRedmail install..." >> $LOGFILE
iredmail
echo "Container requires reboot in order to start iRedMail services." >> $LOGFILE
# shutdown -r now