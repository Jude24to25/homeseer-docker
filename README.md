[![Docker](https://img.shields.io/docker/v/${DOCKER_IMAGE}/latest?color=darkgreen&logo=docker&label=DockerHub%20Latest%20Image)](https://hub.docker.com/repository/docker/${DOCKER_IMAGE}/)
[![Docker](https://img.shields.io/docker/v/${DOCKER_IMAGE}/beta?color=red&logo=docker&label=DockerHub%20Beta%20Image)](https://hub.docker.com/repository/docker/${DOCKER_IMAGE}/)

# Docker Container for HomeSeer 4 (Linux)

(Developed with ♥ by SavageSoftware, LLC.)

## Disclaimers

 -  This repository is not supported, sponsored or directly affiliated with Homeseer ([https://homeseer.com/](https://homeseer.com/)).
 -  We are not responsible for any data lost or systems corrupted! 

---

## Overview

This project provides Docker container images for HomeSeer 4 on Linux.     

The docker images are published via Docker Hub:
 - [https://hub.docker.com/repository/docker/${DOCKER_IMAGE}](https://hub.docker.com/repository/docker/${DOCKER_IMAGE})
 - [![Docker](https://img.shields.io/docker/v/${DOCKER_IMAGE}/latest?label=DockerHub%20Latest%20Image&logo=docker&style=social)](https://hub.docker.com/repository/docker/${DOCKER_IMAGE}/)
 - [![Docker](https://img.shields.io/docker/v/${DOCKER_IMAGE}/beta?label=DockerHub%20Beta%20Image&logo=docker&style=social)](https://hub.docker.com/repository/docker/${DOCKER_IMAGE}/)

---

## TL;DR

Command to launch Docker container:
```
docker run -it --name homeseer \       
       -p 80:80 -p 10200:10200 -p 10300:10300 -p 10401:10401 -p 11000:11000 \
       -v /etc/homeseer:/homeseer \
       ${DOCKER_IMAGE}:latest
```

---

## Supported Architectures

- ARM 64-bit ( `arm64` )
- Intel/AMD 64-bit ( `amd64` / `x86_64` )

---

## Getting Started 

The following docker command will download and launch the latest HomeSeer 4 Docker image.
```shell
docker run \
       --interactive \
       --tty \
       --name homeseer \
       --volume /etc/homeseer:/homeseer \
       --publish 80:80 \
       --publish 10200:10200 \
       --publish 10300:10300 \
       --publish 10401:10401 \
       --publish 11000:11000 \
       --env TZ=America/Los_Angeles \
       --env LANG=en_US.UTF-8 \
       ${DOCKER_IMAGE}:latest
```

On the first run of the `homeseer` container, the script will take a few minutes while it 
installs the HomeSeer application files to the `/homeseer` mapped volume path.  Subsequent 
container restarts will occur much faster as the HomeSeer application files are already 
installed.  If the container is removed and a new container is launched, the HomeSeer
application file will be re-installed even if they already exist in the `/homeseer` 
mapped volume path.  Note: The installation process should not affect any user configuration, 
plugins or log files.  However, it is always a good idea to make sure you have a complete backup 
of the `/homeseer` mapped volume path prior to any upgrades.   

---

## Docker Compose

Alternatively you can use a `docker-compose.yml` file to launch your homeseer container.
Below is a sample `docker-compose.yml` file you can use to get started:

```yaml
# --------------------------------------------------
# HOMESEER LINUX SERVER
# --------------------------------------------------
# This container hosts the HomeSeer V4 server.
# This config will create standalone 'homeseer-data'
# docker volume to store all homeseer runtime
# files. (logs, config, backups, app files)
#
# Disclaimers:
# --------------
# This docker container is not supported, sponsored
# or directly affiliated with Homeseer
# (https://homeseer.com).
#
# --------------------------------------------------
#    (Developed with ♥ by SavageSoftware, LLC.)
# --------------------------------------------------
version: '3.8'

volumes:
  homeseer-data:
    name: homeseer-data

services:
  homeseer:
    container_name: homeseer
    image: ${DOCKER_IMAGE}:latest
    hostname: homeseer
    restart: unless-stopped
    network_mode: bridge
    ports:
      - 80:80
      - 10200:10200
      - 10300:10300
      - 10401:10401
      - 11000:11000
    environment:
      TZ: America/Los_Angeles
      LANG: en_US.UTF-8
    volumes:
      - homeseer-data:/homeseer
```


Just run the `docker-compose up -d` command in the same directory as your `docker-compose.yml` 
file to launch the container instance.

---

## Acknowledgments

Credit must be attributed to the following existing repositories and their respective authors.  Much of 
the logic used in this project was based on these prior works. 

 - https://github.com/marthoc/docker-homeseer
 - https://github.com/scyto/docker-homeseer
 - https://github.com/E1iTeDa357/docker-homeseer4
