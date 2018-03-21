# iRedMail Dockerfile in CentOS 7

This repository contains a Dockerfile to build a Docker Machine for [iRedMail](http://www.iredmail.org/) in CentOS 7

## Base Docker Image
* This Dockerfile builds direct from centos:7

## Installation / Usage
1. Install [Docker](https://www.docker.com/).
2. Edit configuration file (iredmail.cfg)
3. Create/run Container
4. Access iRedAdmin page at http(s)://yourcontainerhost/iredadmin (postmaster@yourprimarydomain and password is as you set in iredmail.cfg)
5. Access Roundcube webmail page at http(s)://yourcontainerhost/mail

### Deploy and Cleanup Scripts
When it came time to update this repo, I found myself doing a lot of manual commands to spin-up a container, find and resolve errors, then numerous commands to clean everything up. No sense in repeating this every time so the following scripts were written for my use and shared here.
#### deploy.sh
This script is used for automatically modifying the *iredmail.cfg* file and running docker-compose up -d with a single command. If you choose to use this method for spinning up an iRedMail container then there is no need to manually edit the *iredmail.cfg* file. The script does the following:
- Creates the data directory on the docker host in /srv/iredmail
- Creates a backup of the iredmail.cfg file
- Customizes the iredmail.cfg for your deployment
- Runs docker-compose up -d to build and launch the container in daemon mode
- Waits 5 seconds then tails the */srv/iredmail/vmail/iredmail-install.log* file so you know when to restart the container for regular usage with docker-compose restart

**NOTE:** If using these scripts on MacOS, be sure to configure docker to add /srv to your Docker preferences under the File Sharing tab. This is the folder that will hold all of your iRedMail data and the iredmail-install.log.

#### cleanup.sh
This is a simple cleanup script that I needed when repeatedly deploying/testing/troubleshooting/cleaning up this container. It does the following:
- kills the currently deployed "iredmail" container
- removes the container from docker
- removes the iredmail:latest image from your system
- restores the modifed iredmail.cfg back to defaults and deletes the backup copy
- (optionally) deletes the /srv/iredmail data (Must uncomment last line of script)

### Build from Github

To create the docker image, clone this repository and execute the following command on the docker-iredmail folder:

```docker build -t burkeazbill/iredmail:latest .```

Alternatively, you can build an image directly from Github:

```docker build -t="burkeazbill/iredmail:latest" github.com/burkeazbill/docker-iredmail```

### Create and run a container

**IMPORTANT: edit the iredmail.cfg file and change domain, default password, and other variables as desired.**

**Create container:**

``` docker create --privileged -it --restart=always -v /srv/iredmail/vmail:/var/vmail -p 80:80 -p 443:443 -p 25:25 -p 587:587 -p 110:110 -p 143:143 -p 993:993 -p 995:995 -h your.hostname.com --name iredmail burkeazbill/iredmail ```

**Create and start a container: (recommended)**

``` docker run --privileged -it --restart=always -v /srv/iredmail/vmail:/var/vmail -p 80:80 -p 443:443 -p 25:25 -p 587:587 -p 110:110 -p 143:143 -p 993:993 -p 995:995 -h your.hostname.com --name iredmail burkeazbill/iredmail ```

--privileged - is required in order for the **systemctl** to function properly

-it runs the container in interactive mode and allocates a pseudo-TTY

--restart=always - allows for you to reboot your container host and have the container run upon reboot

-v maps the container's /var/vmail folder that holds the iRedMail backups to your container host filesystem in /srv/iredmail/vmail

-p provides the necessary port mappings to allow access to the services offered by the container

-h defines your container's hostname

--name defines the name of your running container

The final parameter is the name of the image you wish to run

For more official documentation on run parameters, see: https://docs.docker.com/engine/reference/commandline/run/

**docker-compose**
You may also use docker-compose !
1. Clone the repository
2. Edit the iredmail.cfg to fit your needs
3. Run the following command:

```docker-compose up -d```

## General Notes
Although there are a few other containers for iRedMail out there, they didn't quite fit my needs so I forked one and updated it to suit my needs. In particular, this repository allows you to:
- Disable the SSL redirect on the Roundcube Mail client and iRedAdmin page. I didnt' want this as my intention for this is an isolated test/dev environment.
- Disable the ClamAV/Amavis/Spamassassin integration for the same reasons as disabling SSL.
- Automatically create additional domains
- Automatically create a set of default mailboxes (all of which will use the password defined in the iredmail.cfg file

## To-Do
- incorporate SSL certificate placement