# syntax=docker/dockerfile:1.4
#########################################
# HOMESEER (V4) LINUX - DOCKERFILE
# WITH PLUGIN EXTENSIONS FOR Z-WAVE & MATTER
#########################################

# Base image defined by build arguments
ARG IMAGE_BASE_NAME
ARG IMAGE_BASE_TAG
FROM ${IMAGE_BASE_NAME}:${IMAGE_BASE_TAG}

# Build arguments - define all ARGs early to improve caching
ARG IMAGE_BASE_NAME
ARG IMAGE_BASE_TAG
ARG IMAGE_OUTPUT
ARG HOMESEER_DOWNLOAD_URL
ARG NODEJS_VERSION
ARG HOMESEER_UID
ARG HOMESEER_GID
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

# Define volume
VOLUME ["/homeseer"]

# 1. Configure debconf settings (removed unnecessary mono repository)
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# 2. Update system packages - separated from other installs for better caching
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get full-upgrade -y

# 3. Install locales separately since they rarely change
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y locales && \
    sed -i -e "s/# $LANG UTF-8/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG

# 4. Install container tools and sudo separately
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y acl tmux curl wget nano apt-utils net-tools iputils-ping etherwake ssh-client mosquitto-clients dos2unix \
                      unzip sudo python3

# 5. Install HomeSeer dependencies
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get install -y aha ffmpeg alsa-utils flite chromium avahi-discover libavahi-compat-libdnssd-dev libnss-mdns \
                      avahi-daemon avahi-utils mdns-scan && \
    apt-get remove -y brltty

# 6. Install Mono for non-mono base images - using ARG for conditional execution
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    if [ "$IMAGE_BASE_NAME" = "ubuntu" ]; then \
    # For Ubuntu, use the appropriate repository
        apt-get install -y gnupg ca-certificates && \
        mkdir -p /tmp/gpg && \
        curl -fsSL https://download.mono-project.com/repo/xamarin.gpg | gpg --homedir /tmp/gpg --no-default-keyring --keyring /tmp/mono-archive-keyring.gpg --import && \
        gpg --homedir /tmp/gpg --no-default-keyring --keyring /tmp/mono-archive-keyring.gpg --export --output /usr/share/keyrings/mono-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
        apt-get update && \
        apt-get install -y mono-complete mono-devel; \
    elif [ "$IMAGE_BASE_NAME" = "debian" ]; then \
    # For Debian, use the appropriate repository
        apt-get install -y gnupg ca-certificates && \
        mkdir -p /tmp/gpg && \
        curl -fsSL https://download.mono-project.com/repo/xamarin.gpg | gpg --homedir /tmp/gpg --no-default-keyring --keyring /tmp/mono-archive-keyring.gpg --import && \
        gpg --homedir /tmp/gpg --no-default-keyring --keyring /tmp/mono-archive-keyring.gpg --export --output /usr/share/keyrings/mono-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/debian stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
        apt-get update && \
        apt-get install -y mono-complete mono-devel; \
    elif [ "$IMAGE_BASE_NAME" != "mono" ]; then \
    # For any other base image (that isn't mono)
        apt-get install -y gnupg ca-certificates && \
        mkdir -p /tmp/gpg && \
        curl -fsSL https://download.mono-project.com/repo/xamarin.gpg | gpg --homedir /tmp/gpg --no-default-keyring --keyring /tmp/mono-archive-keyring.gpg --import && \
        gpg --homedir /tmp/gpg --no-default-keyring --keyring /tmp/mono-archive-keyring.gpg --export --output /usr/share/keyrings/mono-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/debian stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
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
    if [ "$IMAGE_BASE_NAME" = "mono" ]; then \
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian buster stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
        apt-get update; \
    elif [ "$IMAGE_BASE_NAME" != "mono" ]; then \
        # Detect distribution and codename
        . /etc/os-release && \
        if [ "$ID" = "ubuntu" ]; then \
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null; \
        elif [ "$ID" = "debian" ]; then \
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $VERSION_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null; \
        else \
            echo "Error: Unsupported distribution '$ID' for Docker repository setup" && exit 1; \
        fi && \
        apt-get update; \
    fi && \
    apt-get install -y docker-ce-cli

# 9. Install specific Node.js version for HomeSeer Matter Controller plugin
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    if [ ! -z "$NODEJS_VERSION" ] && [ "$NODEJS_VERSION" != "none" ]; then \
        apt-get install -y ca-certificates curl gnupg && \
        mkdir -p /etc/apt/keyrings && \
        # Install Matter dependencies
        apt-get install -y bluetooth bluez libbluetooth-dev libudev-dev && \
        # Handle different Node.js version cases
        if [[ "$NODEJS_VERSION" =~ ^[0-9]+$ ]] && [ "$NODEJS_VERSION" -ge 18 ]; then \
            # Case a: Specific version as integer >= 18
            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODEJS_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
            apt-get update && \
            apt-get install -y nodejs make g++ gcc; \
        elif [ "$NODEJS_VERSION" = "default" ]; then \
            # Case b: Use the base image repository's version
            apt-get update && \
            apt-get install -y nodejs npm make g++ gcc; \
        elif [ "$NODEJS_VERSION" = "latest" ]; then \
            # Case c: Use the most recent distro
            curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && \
            apt-get install -y nodejs make g++ gcc; \
        fi && \
        # Only proceed with these steps if we actually installed Node.js (not for "none")
        if [ "$NODEJS_VERSION" != "none" ] && command -v node > /dev/null; then \
            # Allow Node.js directly access Bluetooth hardware when needed
            setcap cap_net_raw+eip $(eval readlink -f `which node`) && \
            # Verify installed version
            node --version && \
            npm --version && \
            # Install additional global packages required for Matter
            npm install -g node-gyp; \
        fi; \
    fi

# 10. Clean up apt cache and remove unused dependencies
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get autoremove -y && \
    apt-get clean

# Expose ports - these rarely change
EXPOSE 80 10200 10300 10401 11000

# Create homeseer user and group with specific IDs
RUN groupadd -g ${HOMESEER_GID} homeseer && useradd -u ${HOMESEER_UID} -g homeseer -m -s /bin/bash homeseer && \
    # Configure sudo to allow homeseer user to use sudo without password
    echo "homeseer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    # Create homeseer directory - do this before download for better caching
    mkdir -p /homeseer && \
    chown -R ${HOMESEER_UID}:${HOMESEER_GID} /homeseer && \
    chmod -R 775 /homeseer && chmod -R g+s /homeseer

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

# Copy avahi config - files rarely change
COPY base/etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf
RUN chmod 664 /etc/avahi/avahi-daemon.conf && \
    # Make an extra copy in a location where homeseer can write
    cp /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf.original && \
    chmod 664 /etc/avahi/avahi-daemon.conf.original

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

# Download HomeSeer - last step since this may change frequently
# Use wget with retry for more reliable downloads
RUN for i in {1..3}; do \
      echo "Downloading HomeSeer (attempt $i)..." && \
      if wget -O /homeseer.tar.gz "$HOMESEER_DOWNLOAD_URL"; then \
        break; \
      elif [ $i -eq 3 ]; then \
        echo "Failed to download HomeSeer after 3 attempts"; \
        exit 1; \
      fi; \
      sleep 2; \
    done && \
    chown -R ${HOMESEER_UID}:${HOMESEER_GID} /homeseer && chmod -R 775 /homeseer && chmod -R g+s /homeseer && setfacl -R -b -k /homeseer

# Docker container image labels with variable values - moved to end to avoid cache invalidation
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