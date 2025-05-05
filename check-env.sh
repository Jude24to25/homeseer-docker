#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

source .env

# Check if all required variables are set
if [ -z "$HOMESEER_DOWNLOAD_URL" ] || [ -z "$BUILD_PLATFORMS" ] || \
   [ -z "$IMAGE_BASE_NAME" ] || [ -z "$IMAGE_BASE_TAG" ] || [ -z "$IMAGE_OUTPUT" ] || \
   [ -z "$LABEL_SCHEMA_URL" ] || [ -z "$LABEL_SCHEMA_VCS_URL" ] || [ -z "$LABEL_SCHEMA_VENDOR" ] || \
   [ -z "$LANG" ] || [ -z "$TZ" ]; then
  echo "Error: One or more required environment variables are not set in .env."
  echo "Please define the following in .env:"
  echo "  HOMESEER_DOWNLOAD_URL (e.g., https://homeseer.com/updates4/linux_4_2_22_4.tar.gz)"
  echo "  IMAGE_BASE_NAME (e.g., mono, ubuntu)"
  echo "  IMAGE_BASE_TAG (e.g., 6.12.0, plucky)"
  echo "  IMAGE_OUTPUT (e.g., localhost/homeseer)"
  echo "  BUILD_PLATFORMS (e.g., linux/arm64)"
  echo "  LABEL_SCHEMA_URL (e.g., https://github.com/Jude24to25/homeseer-docker)"
  echo "  LABEL_SCHEMA_VCS_URL (e.g., https://github.com/Jude24to25/homeseer-docker)"
  echo "  LABEL_SCHEMA_VENDOR (e.g., Jude24to25)"
  echo "  LANG (e.g., en_US.UTF-8)"
  echo "  TZ (e.g., America/Los_Angeles)"
  echo "  "
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
elif [ "$NODEJS_VERSION" != "latest" ] && ! echo "$NODEJS_VERSION" | grep -Eq '^[0-9]+$'; then
  echo "Error: NODEJS_VERSION must be a positive integer (e.g., 18, 20) or 'latest'."
  exit 1
elif [ "$NODEJS_VERSION" != "latest" ] && [ "$NODEJS_VERSION" -lt 18 ]; then
  echo "Error: NODEJS_VERSION must be an integer >= 18 or 'latest'."
  exit 1
fi

echo "ENVIRONMENT VARIABLES"
echo "HomeSeer URL:  $HOMESEER_DOWNLOAD_URL"
echo "Base Image:    $IMAGE_BASE_NAME:$IMAGE_BASE_TAG"
if [ -z "$NODEJS_VERSION" ]; then echo \
     "Node.js:       Default version for base image"
else echo \
      "Node.js:       Version ${NODEJS_VERSION}"
fi
echo "Platform(s):   $BUILD_PLATFORMS"
echo "Output Image:  $IMAGE_OUTPUT"
echo "Timezone:      $TZ"
echo "Language:      $LANG"
echo "  "