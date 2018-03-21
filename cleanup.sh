#!/bin/bash
docker-compose kill
docker-compose rm -f
docker rmi iredmail
cp iredmail.bak iredmail.cfg
rm iredmail.bak