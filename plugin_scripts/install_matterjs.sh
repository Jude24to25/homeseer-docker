#!/bin/bash

DATA_DIR="./Data/MatterController"
BIN_DIR="./bin/MatterController"
MATTER_JS_SERVER_VERSION="$1"
MATTER_JS_SERVER_INSTALL_DIR=$BIN_DIR/matter-js-server

if [ -z "$MATTER_JS_SERVER_VERSION" ]; then
  echo "Error: Please provide the Matter JS server version as a parameter."
  exit 1
fi

echo "Installing Matter JS Server version $MATTER_JS_SERVER_VERSION..."

# Deleting existing install
if [ -d "$MATTER_JS_SERVER_INSTALL_DIR" ]; then
    echo "Deleting existing install"
    rm -rf "$MATTER_JS_SERVER_INSTALL_DIR"
fi

# Create empty installation directory
mkdir -p "$MATTER_JS_SERVER_INSTALL_DIR"

# Extract the archive
echo "Extracting the archive to $MATTER_JS_SERVER_INSTALL_DIR"
unzip -o "$BIN_DIR/matter-js-server-$MATTER_JS_SERVER_VERSION.zip" -d "$MATTER_JS_SERVER_INSTALL_DIR" 

# Install Matter JS Server dependencies
cd "$MATTER_JS_SERVER_INSTALL_DIR"
echo "Installing Dependencies and Building"
npm install --no-update-notifier

# Check if everything is ok
if [ -d "./node_modules" ]; then
    echo "Matter JS Server version $MATTER_JS_SERVER_VERSION installed successfully."
else
    echo "Failed to install Matter JS Server version $MATTER_JS_SERVER_VERSION" >&2
    exit 1
fi