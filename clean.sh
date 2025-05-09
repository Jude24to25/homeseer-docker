#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

#-----------------------------------------------------------------------------------------
# !! THIS DOCKER BUILD REQUIRES THE EXPERIMENTAL DOCKER BUILDX PLUGIN !!
#-----------------------------------------------------------------------------------------
#
# REF: https://docs.docker.com/buildx/working-with-buildx/
#
# Docker Buildx is a CLI plugin that extends the docker command with the
# full support of the features provided by Moby BuildKit builder toolkit.
# It provides the same user experience as docker build with many new
# features like creating scoped builder instances and building against
# multiple nodes concurrently.
#
# This is an experimental feature.
#
# Experimental features provide early access to future product functionality.
# These features are intended for testing and feedback only as they may change
# between releases without warning or can be removed entirely from a future
# release. Experimental features must not be used in production environments.
# Docker does not offer support for experimental features.
#
#-----------------------------------------------------------------------------------------

echo
echo "**********************************************************************"
echo "* CLEANING HOMESEER DOCKER IMAGES                                    *"
echo "**********************************************************************"
echo

# # Load environment variables from .env file if it exists and check if variables are set
# source .env
# ./check-env.sh

# # remove the builder instance
# docker buildx rm homeseer-builder || true
# docker builder prune -a -f
# docker buildx prune -a -f

# # remove any containers from local Docker registry
# docker images -a | grep "${IMAGE_OUTPUT}" | awk '{print $3}' | xargs docker rmi

# Clean unused containers
docker container prune -f

# Clean dangling images
docker image prune -a -f

# Clean build cache
docker buildx prune --all -f

# Clean all unused objects
docker system prune --all -f