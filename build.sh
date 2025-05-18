#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

#-----------------------------------------------------------------------------------------
# !! THIS DOCKER BUILD REQUIRES THE DOCKER BUILDX PLUGIN !!
#-----------------------------------------------------------------------------------------
#  ./build.sh 2>&1 | tee debug.log

# Include debug functionality
source ./debug.sh
log "INFO" "Starting build process..."

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
./env-check.sh

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
  # Use only the first platform when using --load
  if [ "${PUSH_TO_REGISTRY:-false}" != "true" ]; then
    BUILD_PLATFORMS=$(echo "$BUILD_PLATFORMS" | cut -d ',' -f 1)
    echo "Using only $BUILD_PLATFORMS for local build"
  fi
fi

# Create a persistent buildx builder if it doesn't exist
if ! docker buildx inspect homeseer-builder &>/dev/null; then
  echo "Creating persistent buildx builder..."
  docker buildx create --name homeseer-builder --use --driver docker-container --driver-opt network=host
else
  echo "Using existing buildx builder..."
  docker buildx use homeseer-builder
fi

# Initialize buildx for the target platforms
docker buildx inspect --bootstrap

# Set up cache configuration
CACHE_DIR="./.docker-cache"
mkdir -p "$CACHE_DIR"

# Add these cache-specific flags - separate from and to caches
CACHE_FROM="--cache-from=type=local,src=$CACHE_DIR"
CACHE_TO="--cache-to=type=local,dest=$CACHE_DIR,mode=max"

# For better caching on minor changes, set a consistent build timestamp
BUILD_TIMESTAMP="$(date -u +'%Y-%m-%dT00:00:00Z')"

# Use BuildKit inline cache feature
INLINE_CACHE="--build-arg BUILDKIT_INLINE_CACHE=1"

# Initialize REGISTRY_CACHE as empty string
REGISTRY_CACHE=""

# If we're pushing to a registry, enable registry caching
if [ "${PUSH_TO_REGISTRY:-false}" = "true" ]; then
  echo "Enabling registry caching for remote builds"
  REGISTRY_CACHE="--cache-from=type=registry,ref=${IMAGE_OUTPUT}:buildcache --cache-to=type=registry,ref=${IMAGE_OUTPUT}:buildcache,mode=max"
fi

# Determine whether to use --load or --push
if [ "${PUSH_TO_REGISTRY:-false}" = "true" ]; then
  OUTPUT_FLAG="--push"
  echo "Building for registry push"
else
  OUTPUT_FLAG="--load"
  echo "Building for local use (--load)"
fi

# Display buildx info
echo "Using buildx builder with capabilities:"
docker buildx inspect

#-----------------------------------------------------------------------------------------
# Build HomeSeer image
echo "Building HomeSeer image: ${IMAGE_OUTPUT}:$VERSION"
echo "Using platforms: $BUILD_PLATFORMS"
echo "Cache directory: $CACHE_DIR"

# Use --progress=plain during development, auto for production
PROGRESS="--progress=plain"

# Build the image
docker buildx build \
  $PROGRESS \
  $CACHE_FROM \
  $CACHE_TO \
  $REGISTRY_CACHE \
  $INLINE_CACHE \
  --build-arg IMAGE_BASE_NAME="${IMAGE_BASE_NAME}" \
  --build-arg IMAGE_BASE_TAG="${IMAGE_BASE_TAG}" \
  --build-arg IMAGE_OUTPUT="${IMAGE_OUTPUT}" \
  --build-arg HOMESEER_DOWNLOAD_URL="$HOMESEER_DOWNLOAD_URL" \
  --build-arg NODEJS_VERSION="${NODEJS_VERSION}" \
  --build-arg HOMESEER_UID="${HOMESEER_UID}" \
  --build-arg HOMESEER_GID="${HOMESEER_GID}" \
  --build-arg TZ="$TZ" \
  --build-arg LANG="$LANG" \
  --build-arg VERSION="$VERSION" \
  --build-arg BUILDDATE="$BUILD_TIMESTAMP" \
  --build-arg LABEL_SCHEMA_URL="$LABEL_SCHEMA_URL" \
  --build-arg LABEL_SCHEMA_VCS_URL="$LABEL_SCHEMA_VCS_URL" \
  --build-arg LABEL_SCHEMA_VENDOR="$LABEL_SCHEMA_VENDOR" \
  --build-arg DEBIAN_FRONTEND="noninteractive" \
  --tag "${IMAGE_OUTPUT}:${IMAGE_BASE_NAME}-${IMAGE_BASE_TAG}${IMAGE_EXTRA_TAG}" \
  --tag "${IMAGE_OUTPUT}:${IMAGE_BASE_NAME}-${IMAGE_BASE_TAG}_homeseer-${VERSION}${IMAGE_EXTRA_TAG}" \
  --tag "${IMAGE_OUTPUT}:${IMAGE_BASE_NAME}-${IMAGE_BASE_TAG}_homeseer-latest${IMAGE_EXTRA_TAG}" \
  --platform "$BUILD_PLATFORMS" \
  --file Dockerfile \
  $OUTPUT_FLAG \
  . || {
    echo "Warning: Build failed, checking for images anyway..."
    docker images | grep "${IMAGE_OUTPUT}" || echo "No images found for ${IMAGE_OUTPUT}"
    exit 1
  }

# Show the built images
echo "Build completed. Available images:"
docker images | grep "${IMAGE_OUTPUT}" || echo "No images found for ${IMAGE_OUTPUT}"
log "INFO" "Build process completed successfully"

# Disable tracing before exit (if enabled)
if [[ "$DEBUG" -eq 1 ]]; then
  set +x
fi