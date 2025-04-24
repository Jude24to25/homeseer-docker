#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

source .env

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
  echo "  BUILD_PLATFORMS (e.g., 'linux/amd64' or 'linux/arm64'"
  exit 1
fi

# Validate BUILD_PLATFORMS
if ! echo "$BUILD_PLATFORMS" | grep -Eq '^(linux/amd64|linux/arm64)$'; then
  echo "Error: BUILD_PLATFORMS must be 'linux/amd64' or 'linux/arm64'."
  exit 1
fi