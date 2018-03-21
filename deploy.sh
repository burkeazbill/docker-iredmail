#!/bin/bash
mkdir -p /srv/iredmail
cp iredmail.cfg iredmail.bak
# Update iredmail.cfg file for HOL vPod use:
sed -i 's/yourdomain.lab/rainpole.com/g' ./iredmail.cfg
# Note the use of single quote on next line - this is due to ! being special char
sed -i 's/Passw0rd!/VMware1!/g' ./iredmail.cfg
sed -i 's/x.x.x.x/192.168.110.10/g' ./iredmail.cfg
sed -i 's/domain2.lab domain3.lab/corp.local abigtelco.com/g' ./iredmail.cfg
sed -i 's/# NTPSERVER=.*/NTPSERVER="ntp.corp.local"/g' ./iredmail.cfg
sed -i 's/PRIMARY_DOMAIN_USERS=.*/PRIMARY_DOMAIN_USERS="administrator ceo cfo cio cloudadmin cmo devmgr devuser ecomops epa infosec itmgr itop-notification gitlab jdev ldev loginsight projmgr rpadmin vra"/g' ./iredmail.cfg
# Update docker-compose file with hostname:
sed -i 's/utility/mail.rainpole.com/g' ./docker-compose.yml
# Now, add two lines to the iredmail.sh script to add all the primary domain users to the corp.local domain as well
# Duplicate the following 2 lines for each additional domain you wish to add the users to
sed -i '/duration=/i\ \ \ \ \ \ \ \ /bin/bash create_mail_user_SQL.sh corp.local $PRIMARY_DOMAIN_USERS' iredmail/iredmail.sh
sed -i '/duration=/i\ \ \ \ \ \ \ \ /usr/bin/mysql -uroot -p$PASSWD vmail < /opt/iredmail/iRedMail-$IREDMAIL_VERSION/tools/output.sql' iredmail/iredmail.sh
# Build and launch Container:
docker-compose up -d
sleep 5
tail -f /srv/iredmail/vmail/*.log