#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

#-----------------------------------------------------------------------------------------
# !! THIS DOCKER BUILD REQUIRES THE DOCKER BUILDX PLUGIN !!
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
# Ensure Buildx is installed and configured (included in Docker Desktop and CLI).#
#-----------------------------------------------------------------------------------------

echo
echo "**********************************************************************"
echo "* BUILDING HOMESEER LINUX DOCKER IMAGE                               *"
echo "**********************************************************************"
echo

# Ensure DOCKER_HOST is set for socket-proxy
if [ -z "$DOCKER_HOST" ]; then
  export DOCKER_HOST=tcp://socket-proxy:2375
fi

# Load environment variables from .env file if it exists and check if variables are set
source .env
./check-env.sh

# Extract version from HOMESEER_DOWNLOAD_URL
VERSION=$(basename "$HOMESEER_DOWNLOAD_URL" | sed -n 's/.*linux_\([0-9]_[0-9]_[0-9]\{1,\}_[0-9]\).*/\1/p' | tr '_' '.')
if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version from HOMESEER_DOWNLOAD_URL."
  exit 1
fi
echo "HS Version:    $VERSION"
echo "  "

# Warn about multi-platform builds with --load
if echo "$BUILD_PLATFORMS" | grep -q ',' && [ "${PUSH_TO_REGISTRY:-false}" != "true" ]; then
  echo "Warning: Multi-platform builds ($BUILD_PLATFORMS) require --push to a registry. Using --load for single platform only."
fi

#-----------------------------------------------------------------------------------------
# # Perform multi-arch platform image builds
# # Set up Buildx for multi-platform builds
# echo "Setting up Docker Buildx for platform: $BUILD_PLATFORMS"
# docker buildx create --use --name homeseer-builder --platform $BUILD_PLATFORMS

# # Ensure Buildx builder is cleaned up on exit
# trap 'docker buildx rm homeseer-builder 2>/dev/null || true' EXIT

# Create a persistent buildx builder if it doesn't exist
if ! docker buildx inspect homeseer-builder &>/dev/null; then
  echo "Creating persistent buildx builder..."
  docker buildx create --name homeseer-builder --use
else
  echo "Using existing buildx builder..."
  docker buildx use homeseer-builder
fi

# Add these cache-specific flags
CACHE_FLAGS=" --cache-to=type=local,dest=./docker-cache,mode=max"

#-----------------------------------------------------------------------------------------
# Build HomeSeer image
echo "Building HomeSeer image: ${IMAGE_OUTPUT}:$VERSION"
docker buildx build \
  --progress=plain \
  $CACHE_FLAGS \
  --build-arg IMAGE_BASE_NAME="${IMAGE_BASE_NAME}" \
  --build-arg IMAGE_BASE_TAG="${IMAGE_BASE_TAG}" \
  --build-arg IMAGE_OUTPUT="${IMAGE_OUTPUT}" \
  --build-arg HOMESEER_DOWNLOAD_URL="$HOMESEER_DOWNLOAD_URL" \
  --build-arg TZ="$TZ" \
  --build-arg LANG="$LANG" \
  --build-arg VERSION="$VERSION" \
  --build-arg BUILDDATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg LABEL_SCHEMA_URL="$LABEL_SCHEMA_URL" \
  --build-arg LABEL_SCHEMA_VCS_URL="$LABEL_SCHEMA_VCS_URL" \
  --build-arg LABEL_SCHEMA_VENDOR="$LABEL_SCHEMA_VENDOR" \
  --build-arg DEBIAN_FRONTEND="noninteractive" \
  --tag "${IMAGE_OUTPUT}:latest" \
  --tag "${IMAGE_OUTPUT}:$VERSION" \
  --platform "$BUILD_PLATFORMS" \
  --file Dockerfile \
  --load \
  . || {
    echo "Warning: Build failed, checking for images anyway..."
    docker images | grep "${IMAGE_OUTPUT}" || echo "No images found for ${IMAGE_OUTPUT}"
    exit 1
  }

docker images | grep "${IMAGE_OUTPUT}"

#   --cache-from=type=local,src="${IMAGE_OUTPUT}:latest" \