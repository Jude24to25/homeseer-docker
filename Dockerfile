# syntax=docker/dockerfile:1.4
#########################################
# HOMESEER (V4) LINUX - DOCKERFILE
# WITH PLUGIN EXTENSIONS FOR Z-WAVE & MATTER
#########################################

# Base image defined by build arguments
ARG IMAGE_BASE_NAME
ARG IMAGE_BASE_TAG
FROM ${IMAGE_BASE_NAME}:${IMAGE_BASE_TAG}

# Build arguments
ARG IMAGE_BASE_NAME
ARG IMAGE_BASE_TAG
ARG IMAGE_OUTPUT
ARG HOMESEER_DOWNLOAD_URL
ARG NODEJS_VERSION=18
ARG TZ
ARG LANG
ARG VERSION
ARG BUILDDATE
ARG LABEL_SCHEMA_URL
ARG LABEL_SCHEMA_VCS_URL
ARG LABEL_SCHEMA_VENDOR
ARG DEBIAN_FRONTEND

# Early set of environment variables (improves caching)
ENV LANG="$LANG" \
    TZ="$TZ" \
    HOMESEER_CREDENTIALS="" \
    DEBIAN_FRONTEND="noninteractive" \
    DOCKER_HOST="tcp://socket-proxy:2375"

# Custom STOP signal
STOPSIGNAL SIGQUIT

# Docker container image labels (generic ones that don't change often)
LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.description="HomeSeer Docker Image with Z-Wave Plus and Matter Controller Support"

# Install dependencies and configure - split into logical, cacheable steps
# 1. Configure apt repositories
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    echo "deb [trusted=yes] https://download.mono-project.com/repo/debian stable-buster/snapshots/6.12.0.182 main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# 2. Update system packages - separated from other installs for better caching
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get upgrade -y

# 3. Install locales separately since they rarely change
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y locales && \
    sed -i -e "s/# $LANG UTF-8/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG

# 4. Install container tools separately 
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y acl tmux curl wget nano apt-utils net-tools iputils-ping etherwake ssh-client mosquitto-clients dos2unix \
                      unzip

# 5. Install HomeSeer dependencies
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y aha ffmpeg alsa-utils flite chromium avahi-discover libavahi-compat-libdnssd-dev libnss-mdns \
                      avahi-daemon avahi-utils mdns-scan && \
    apt-get remove -y brltty

# 6. Install Mono for non-mono base images - using ARG for conditional execution
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    if [ "$IMAGE_BASE_NAME" != "mono" ]; then \
      apt-get install -y gnupg ca-certificates && \
      gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
      echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
      apt-get update && \
      apt-get install -y mono-complete mono-devel; \
    fi

# 7. Install additional Mono components
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y mono-vbnc mono-xsp4

# 8. Install Docker CLI (for plugin support) - we'll use the host's Docker daemon via socket-proxy
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian buster stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# 9. Install specific Node.js version for HomeSeer Matter Controller plugin
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    # Download and set up Node.js repository for specified version
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODEJS_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    # Install Node.js with additional build dependencies needed for native modules
    apt-get install -y nodejs make g++ gcc && \
    # Verify installed version
    node --version && \
    npm --version && \
    # Install additional global packages required for Matter
    npm install -g node-gyp

# Clean up apt cache
RUN apt-get clean

# Create homeseer user and group with specific IDs
RUN groupadd -g 1000 homeseer && useradd -u 1000 -g homeseer -m -s /bin/bash homeseer

# Copy HomeSeer override and container runtime scripts from base/
# Separate copy commands for better caching when scripts change
COPY base/homeseer/*.sh /scripts/
COPY base/usr/local/sbin/* /scripts/

# Configure scripts - this rarely changes so it should be cacheable
RUN chmod a+x /scripts/* && \
    dos2unix /scripts/* && \
    rm -f /sbin/reboot && rm -f /sbin/shutdown && \
    ln -sf /scripts/homeseer /usr/local/sbin/homeseer && \
    ln -sf /scripts/reboot /usr/local/sbin/reboot && \
    ln -sf /scripts/shutdown /usr/local/sbin/shutdown && \
    ln -sf /scripts/poweroff /usr/local/sbin/poweroff

# Fix for timezone and permissions - pre-configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    mkdir -p /var/lib/dbus /var/run/dbus /var/run/avahi-daemon && \
    # Fix permissions for key directories and files
    chown -R homeseer:homeseer /var/lib/dbus /var/run/dbus && \
    chmod 775 /var/lib/dbus /var/run/dbus && \
    # Set proper permissions for avahi
    chown avahi:avahi /var/run/avahi-daemon && \
    # Create a copy of avahi config that homeseer user can modify
    mkdir -p /etc/avahi && \
    chmod 775 /etc/avahi

# Copy avahi config
COPY base/etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf
RUN chmod 664 /etc/avahi/avahi-daemon.conf && \
    # Make an extra copy in a location where homeseer can write
    cp /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf.original && \
    chmod 664 /etc/avahi/avahi-daemon.conf.original

# Expose ports
EXPOSE 80 10200 10300 10401 11000 8091 3000

# Define volume
VOLUME ["/homeseer"]

# Download HomeSeer - last step since this may change frequently
# Use curl with retry for more reliable downloads
RUN mkdir -p /homeseer && \
    chown homeseer:homeseer /homeseer && \
    chmod -R 775 /homeseer && \
    for i in {1..3}; do \
      echo "Downloading HomeSeer (attempt $i)..." && \
      if wget -O /homeseer.tar.gz "$HOMESEER_DOWNLOAD_URL"; then \
        break; \
      elif [ $i -eq 3 ]; then \
        echo "Failed to download HomeSeer after 3 attempts"; \
        exit 1; \
      fi; \
      sleep 2; \
    done

# Docker container image labels (moved to end to avoid cache invalidation)
LABEL org.label-schema.build-date=$BUILDDATE \
      org.label-schema.name="${IMAGE_OUTPUT}" \
      org.label-schema.url="$LABEL_SCHEMA_URL" \
      org.label-schema.vcs-url="$LABEL_SCHEMA_VCS_URL" \
      org.label-schema.vendor="$LABEL_SCHEMA_VENDOR" \
      org.label-schema.version="$VERSION"

# Set user and working directory
USER homeseer
WORKDIR /homeseer
ENTRYPOINT ["/usr/local/sbin/homeseer"]