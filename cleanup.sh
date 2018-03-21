#!/bin/bash
docker-compose kill
docker-compose rm -f
docker rmi iredmail
cp iredmail.bak iredmail.cfg
rm iredmail.bak
# Uncomment following line if you want the data in docker host volume
# cleaned up as well. This is recommended for clean testing
# rm -Rf /srv/iredmail