# iRedMail Dockerfile in CentOS 7

This repository contains a Dockerfile to build a Docker Machine for iRedMail in CentOS 7

## Base Docker Image

* This Dockerfile builds direct from centos:latest

## Usage

### Installation

1. Install [Docker](https://www.docker.com/).
2. Edit configuration file (iredmail.cfg)
3. Create/run Container
4. Access iRedAdmin page at http(s)://yourcontainerhost/iredadmin
5. Access Roundcube webmail page at http(s)://yourcontainerhost/mail

**Another way: build from Github**

To create the docker image, clone this repository and execute the following command on the docker-iredmail folder:

`docker build -t burkeazbill/iredmail:latest .`

Another alternatively, you can build an image directly from Github:

`docker build -t="burkeazbill/iredmail:latest" github.com/burkeazbill/docker-iredmail`

### Create and running a container

**IMPORTANT: edit the iredmail.cfg file and change domain, default password, and other variables as desired.**

**Create container:**

``` docker create --privileged -it --restart=always -v /srv/iredmail/vmail:/var/vmail -p 80:80 -p 443:443 -p 25:25 -p 587:587 -p 110:110 -p 143:143 -p 993:993 -p 995:995 -h your.hostname.com --name iredmail burkeazbill/iredmail ```

**Start container:**

``` docker start iredmail ```


**Another way to create and start a container:**

``` docker run --privileged -it --restart=always -v /srv/iredmail/vmail:/var/vmail -p 80:80 -p 443:443 -p 25:25 -p 587:587 -p 110:110 -p 143:143 -p 993:993 -p 995:995 -h your.hostname.com --name iredmail burkeazbill/iredmail ```

**General Notes**
Although there are a few other containers for iRedMail out there, they didn't quite fit my needs so I forked one and updated it to suit my needs. In particular, this repository allows you to:
- Disable the SSL redirect on the Roundcube Mail client and iRedAdmin page. I didnt' want this as my intention for this is an isolated test/dev environment.
- Disable the ClamAV/Amavis/Spamassassin integration for the same reasons as disabling SSL.
- Automatically create additional domains
- Automatically create a set of default mailboxes (all of which will use the password defined in the iredmail.cfg file
