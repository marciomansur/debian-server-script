# Debian server provisioner

Configure a new server could be a painful thing to do, there's a lot of things to set, and something wrong could break your entire application.

This tool automates a debian server provisioning, installing and configuring some initial settings.

## Pre-requisites

 - A debian server (it can be a VM or a cloud instance)
 - An user in this server, with sudo privilegies
 - A SSH Key configured on your host

## How to use it?

First, clone this repo in your station (not in server):

```
git clone https://github.com/marciomansur/debian-server-script
```

Change `.env.example.sh` to `env.sh` and fill the env settings matching with your server

```
mv .env.example.sh env.sh
```

These are the environment variables:

```
export SERVER_IP="${SERVER_IP:-your-server-ip}"
export SSH_USER="${SSH_USER:-$(whoami)}"
export SERVER_USER="${SERVER_USER:-$(whoami)}"
export DOCKER_VERSION="${DOCKER_VERSION:-17.03}"
```
