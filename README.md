[![Docker](https://img.shields.io/docker/v/${IMAGE_OUTPUT}/latest?color=darkgreen&logo=docker&label=DockerHub%20Latest%20Image)](https://hub.docker.com/repository/docker/${IMAGE_OUTPUT}/)
[![Docker](https://img.shields.io/docker/v/${IMAGE_OUTPUT}/beta?color=red&logo=docker&label=DockerHub%20Beta%20Image)](https://hub.docker.com/repository/docker/${IMAGE_OUTPUT}/)

# Docker Container for HomeSeer 4 (Linux)

Forked from SavageSoftware

(Developed with ♥ by SavageSoftware, LLC.)

## Disclaimers

 -  This repository is not supported, sponsored or directly affiliated with Homeseer ([https://homeseer.com/](https://homeseer.com/)).
 -  We are not responsible for any data lost or systems corrupted! 
 -  This is a personal project for testing different ways to implement SavageSoftware's AWESOME work on a Docker-version of HomeSeer. Primary goals for modifications are as follows:
    1. Separate out user-definable parameters into a .env file
    2. Make it easier to specify where sources are being downloaded from (e.g., HomeSeer files come from HomeSeer, etc.)
    3. Output images to local computer instead of remote repository

---

## Acknowledgments

Credit must be attributed to the following existing repositories and their respective authors.  Much of 
the logic used in this project was based on these prior works. 
 - https://github.com/HomeSeerLinux/homeseer-docker
 - https://github.com/marthoc/docker-homeseer
 - https://github.com/scyto/docker-homeseer
 - https://github.com/E1iTeDa357/docker-homeseer4
