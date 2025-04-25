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
echo "* BUILDING HOMESEER LINUX DOCKER IMAGE                               *"
echo "**********************************************************************"
echo

# Load environment variables from .env file if it exists and check if variables are set
source .env
./check-env.sh

# Extract version from HOMESEER_DOWNLOAD_URL
VERSION=$(basename "$HOMESEER_DOWNLOAD_URL" | sed -n 's/.*linux_\([0-9]_[0-9]_[0-9]\{1,\}_[0-9]\).*/\1/p' | tr '_' '.')
if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version from HOMESEER_DOWNLOAD_URL."
  exit 1
fi
echo "Extracted HomeSeer version: $VERSION"

#-----------------------------------------------------------------------------------------
# Build the base image and then HomeSeer image
echo "Building base image: ${DOCKER_IMAGE_BASE}:latest"
./base/build.sh

# Perform multi-arch platform image builds; push the resulting image to repository (https://hub.docker.com/r/${DOCKER_IMAGE})
echo "Building HomeSeer image: ${DOCKER_IMAGE}:latest"

docker build \
  --build-arg VERSION="$VERSION" \
  --build-arg DOCKER_IMAGE="${DOCKER_IMAGE}" \
  --build-arg DOCKER_IMAGE_BASE="${DOCKER_IMAGE_BASE}" \
  --build-arg HOMESEER_DOWNLOAD_URL="$HOMESEER_DOWNLOAD_URL" \
  --build-arg LABEL_SCHEMA_URL="$LABEL_SCHEMA_URL" \
  --build-arg LABEL_SCHEMA_VCS_URL="$LABEL_SCHEMA_VCS_URL" \
  --build-arg LABEL_SCHEMA_VENDOR="$LABEL_SCHEMA_VENDOR" \
  --tag "${DOCKER_IMAGE}:$VERSION" \
  --tag "${DOCKER_IMAGE}:latest" \
  --cache-from ${DOCKER_IMAGE}:latest \
  --file Dockerfile \
  --load \
  .
docker images | grep "${DOCKER_IMAGE}"