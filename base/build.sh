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

# docker image version
echo
echo "**********************************************************************"
echo "* BUILDING HOMESEER LINUX BASE DOCKER IMAGE                          *"
echo "**********************************************************************"
echo

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  source .env
fi

# Check if all required variables are set
if [ -z "$DOCKER_IMAGE" ] || [ -z "$DOCKER_IMAGE_BASE" ] || [ -z "$HOMESEER_DOWNLOAD_URL" ] || \
   [ -z "$LABEL_SCHEMA_URL" ] || [ -z "$LABEL_SCHEMA_VCS_URL" ] || [ -z "$LABEL_SCHEMA_VENDOR" ] || \
   [ -z "$BUILD_PLATFORMS" ]; then
  echo "Error: One or more required environment variables are not set in .env."
  echo "Please define the following in .env:"
  echo "  DOCKER_IMAGE (e.g., XYZ/homeseer)"
  echo "  DOCKER_IMAGE_BASE (e.g., XYZ/homeseer-base)"
  echo "  HOMESEER_DOWNLOAD_URL (e.g., https://homeseer.com/updates4/linux_4_2_22_4.tar.gz)"
  echo "  LABEL_SCHEMA_URL (e.g., https://github.com/Jude24to25/homeseer-docker)"
  echo "  LABEL_SCHEMA_VCS_URL (e.g., https://github.com/Jude24to25/homeseer-docker)"
  echo "  LABEL_SCHEMA_VENDOR (e.g., XYZ)"
  echo "  BUILD_PLATFORMS (e.g., linux/amd64; linux/arm64; or linux/amd64,linux/arm64)"
  exit 1
fi

# Validate BUILD_PLATFORMS
if ! echo "$BUILD_PLATFORMS" | grep -Eq '^(linux/amd64|linux/arm64)$'; then
  echo "Error: BUILD_PLATFORMS must be 'linux/amd64' or 'linux/arm64'."
  exit 1
fi

# Use buildx to create a new builder instance; if needed
docker buildx create --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10485760   \
                     --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=100000000 \
                     --use --name ${DOCKER_IMAGE_BASE##*/}-builder || true;

# Perform multi-arch platform image builds
docker buildx build \
  --build-arg VERSION="base" \
  --build-arg LABEL_SCHEMA_URL="$LABEL_SCHEMA_URL" \
  --build-arg LABEL_SCHEMA_VCS_URL="$LABEL_SCHEMA_VCS_URL" \
  --build-arg LABEL_SCHEMA_VENDOR="$LABEL_SCHEMA_VENDOR" \
  --platform "$BUILD_PLATFORMS" \
  --tag ${DOCKER_IMAGE_BASE}:latest \
  --cache-from=type=registry,ref="${DOCKER_IMAGE_BASE}:latest" \
  --cache-to=type=inline \
  --load \
  -f base/Dockerfile base/ $@
