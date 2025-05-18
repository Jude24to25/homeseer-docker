#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

source .env

# Check if all required variables are set
if [ -z "$HOMESEER_DOWNLOAD_URL" ] || [ -z "$BUILD_PLATFORMS" ] || \
   [ -z "$IMAGE_BASE_NAME" ] || [ -z "$IMAGE_BASE_TAG" ] || [ -z "$IMAGE_OUTPUT" ] || \
   [ -z "$NODEJS_VERSION" ] || [ -z "$HOMESEER_UID" ] || [ -z "$HOMESEER_GID" ] || \
   [ -z "$LABEL_SCHEMA_URL" ] || [ -z "$LABEL_SCHEMA_VCS_URL" ] || [ -z "$LABEL_SCHEMA_VENDOR" ] || \
   [ -z "$LANG" ] || [ -z "$TZ" ]; then
  echo "Error: One or more required environment variables are not set in .env."
  echo "Please check the following and define any missing variables in .env:"
  ./env-display.sh
  exit 1
fi

# Validate BUILD_PLATFORMS
if ! echo "$BUILD_PLATFORMS" | grep -Eq '^(linux/amd64|linux/arm64|linux/amd64,linux/arm64)$'; then
  echo "Error: BUILD_PLATFORMS must be 'linux/amd64', 'linux/arm64', or 'linux/amd64,linux/arm64'."
  exit 1
fi

# Validate IMAGE_BASE_NAME
if ! echo "$IMAGE_BASE_NAME" | grep -Eq '^(mono|debian|ubuntu)$'; then
  echo "Error: IMAGE_BASE_NAME must be 'mono', 'debian', or 'ubuntu'."
  exit 1
fi

# Validate LANG
if ! echo "$LANG" | grep -Eq '^[a-z]{2}_[A-Z]{2}\.UTF-8$'; then
  echo "Error: LANG must be a valid UTF-8 locale (e.g., en_US.UTF-8, fr_FR.UTF-8)."
  exit 1
fi

# Validate TZ
if ! [ -f "/usr/share/zoneinfo/$TZ" ] && ! [ -d "/usr/share/zoneinfo/$TZ" ]; then
  echo "Error: TZ must be a valid timezone (e.g., America/Los_Angeles)."
  exit 1
fi

# Validate NODEJS_VERSION
if [ -z "$NODEJS_VERSION" ]; then
  echo "Error: NODEJS_VERSION must not be blank."
  exit 1
elif [ "$NODEJS_VERSION" == "none" ]; then
  : # NodeJS installation disabled, no output needed
elif [ "$NODEJS_VERSION" == "default" ]; then
  : # Using default NodeJS version, no output needed
elif [ "$NODEJS_VERSION" == "latest" ]; then
  : # Using latest NodeJS version, no output needed
elif echo "$NODEJS_VERSION" | grep -Eq '^[0-9]+$' ; then
  if [ "$NODEJS_VERSION" -lt 18 ]; then
    echo "Error: When specifying a numeric NODEJS_VERSION, it must be >= 18."
    exit 1
  fi
  # Valid specific version, no output needed
else
  echo "Error: NODEJS_VERSION must be a positive integer >= 18, 'latest', 'default', or 'none'."
  exit 1
fi

# Validate PUSH_TO_REGISTRY
if [[ -z "$PUSH_TO_REGISTRY" || "$PUSH_TO_REGISTRY" != "true" && "$PUSH_TO_REGISTRY" != "false" ]]; then
  echo "Error: PUSH_TO_REGISTRY must be set to either 'true' or 'false'"
  exit 1
fi

./env-display.sh