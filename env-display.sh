#!/bin/bash -e

############################################
# HOMESEER (V4) LINUX - DOCKER BUILD SCRIPT
############################################

source .env

BLANK_ERROR="***MISSING***"

echo "ENVIRONMENT VARIABLES"
echo "HomeSeer URL:  ${HOMESEER_DOWNLOAD_URL:-$BLANK_ERROR}"
echo "Base Image:    ${IMAGE_BASE_NAME:-$BLANK_ERROR}:${IMAGE_BASE_TAG:-$BLANK_ERROR}"
echo "Node Version:  ${NODEJS_VERSION:-$BLANK_ERROR}"
echo "UID:           ${HOMESEER_UID:-$BLANK_ERROR}"
echo "GID:           ${HOMESEER_GID:-$BLANK_ERROR}"
echo "Platform(s):   ${BUILD_PLATFORMS:-$BLANK_ERROR}"
echo "Output Image:  ${IMAGE_OUTPUT:-$BLANK_ERROR}"
echo "Timezone:      ${TZ:-$BLANK_ERROR}"
echo "Language:      ${LANG:-$BLANK_ERROR}"
echo "  "