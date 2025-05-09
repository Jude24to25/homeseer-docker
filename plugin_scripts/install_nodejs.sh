#!/bin/bash

NODEJS_MAJOR_VERSION="$1"

if [ -z "$NODEJS_MAJOR_VERSION" ]; then
  echo "Error: Please provide the Node.js major version as a parameter."
  exit 1
fi

echo "Installing Node.js version $NODEJS_MAJOR_VERSION.x ..."

if command -v dpkg > /dev/null 2>&1; then
    echo "Debian-based distribution detected"
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODEJS_MAJOR_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install nodejs make g++ gcc -y

elif command -v rpm > /dev/null 2>&1; then
    echo "RPM-based distribution detected"
    sudo yum install https://rpm.nodesource.com/pub_$NODEJS_MAJOR_VERSION.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
    sudo yum install nodejs gcc-c++ make -y --setopt=nodesource-nodejs.module_hotfixes=1
else
    echo "Linux distribution unsupported. Please install Node.js version $NODEJS_MAJOR_VERSION manually" >&2
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Failed to install Node.js version $NODEJS_MAJOR_VERSION.x" >&2
    exit 1
fi

# Get the current Node.js version
CURRENT_VERSION=$(node -v | sed 's/^v//')  # Remove the "v" prefix from version
# Get the current major version of Node.js
CURRENT_MAJOR_VERSION=$(node -v | sed -E 's/^v([0-9]+).*/\1/')

# Compare the major versions as strings
if [[ "$CURRENT_MAJOR_VERSION" < "$NODEJS_MAJOR_VERSION" ]]; then
    echo "Failed to install Node.js version $NODEJS_MAJOR_VERSION.x, currently installed version is $CURRENT_VERSION" >&2
    exit 1
else
    echo "Node.js version $CURRENT_VERSION has been successfully installed."
fi