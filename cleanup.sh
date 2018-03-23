#!/bin/bash
docker-compose kill
docker-compose rm -f
docker rmi iredmail
# Now reset files back to original and remove *.bak
cat iredmail.bak > iredmail.cfg
cat docker-compose.bak > docker-compose.yml
cat iredmail/iredmail.bak iredmail/iredmail.sh
find ./ -name "*.bak" -type f -delete
# Uncomment following line if you want the data in docker host volume
# cleaned up as well. This is recommended for clean testing
# rm -Rf /srv/iredmail