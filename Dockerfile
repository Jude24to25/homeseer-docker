#########################################
# HOMESEER (V4) LINUX - DOCKERFILE
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
ARG TZ
ARG LANG
ARG VERSION
ARG BUILDDATE
ARG LABEL_SCHEMA_URL
ARG LABEL_SCHEMA_VCS_URL
ARG LABEL_SCHEMA_VENDOR
ARG DEBIAN_FRONTEND

# Custom STOP signal
STOPSIGNAL SIGQUIT

# Environment variables
ENV LANG="$LANG"
ENV TZ="$TZ"
ENV HOMESEER_CREDENTIALS=""

# Docker container image labels
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILDDATE
LABEL org.label-schema.name="${IMAGE_OUTPUT}"
LABEL org.label-schema.description="HomeSeer Docker Image"
LABEL org.label-schema.url="$LABEL_SCHEMA_URL"
LABEL org.label-schema.vcs-url="$LABEL_SCHEMA_VCS_URL"
LABEL org.label-schema.vendor="$LABEL_SCHEMA_VENDOR"
LABEL org.label-schema.version="$VERSION"

# Verify input variables
RUN echo "ENVIRONMENT VARIABLES" && \
    echo "HomeSeer URL:  $HOMESEER_DOWNLOAD_URL" && \
    echo "Base Image:    ${IMAGE_BASE_NAME}:${IMAGE_BASE_TAG}" && \
    echo "Output Image:  $IMAGE_OUTPUT" && \
    echo "Timezone:      $TZ" && \
    echo "Language:      $LANG" && \
    echo "Version:       $VERSION" && \
    echo "Build Date:    $BUILDDATE" && \
    echo " "

# Install dependencies and configure
RUN apt-get update && \
    apt-get upgrade -y && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
#   Update locale/language
    apt-get install -y locales && \
    sed -i -e "s/# $LANG UTF-8/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG && \
#   Install container tools
    apt-get install -y tmux curl wget nano apt-utils net-tools iputils-ping etherwake ssh-client mosquitto-clients dos2unix && \
#   Install HomeSeer dependencies
    apt-get install -y aha ffmpeg alsa-utils flite chromium avahi-discover libavahi-compat-libdnssd-dev libnss-mdns \
                      avahi-daemon avahi-utils mdns-scan && \
    apt-get remove -y brltty && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Mono for non-mono base images
RUN if [ "$IMAGE_BASE_NAME" != "mono" ]; then \
      apt-get update && \
      apt-get install -y gnupg ca-certificates && \
      gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
      echo "deb [signed-by=/usr/share/keyrings/mono-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
      apt-get update && \
      apt-get install -y mono-complete mono-devel && \
      apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi && \
    apt-get update && \
    apt-get install -y mono-vbnc mono-xsp4 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create homeseer user
RUN groupadd -g 1000 homeseer && useradd -u 1000 -g homeseer -m -s /bin/bash homeseer

# Copy HomeSeer override and container runtime scripts from base/
COPY base/homeseer/*.sh /scripts/
COPY base/usr/local/sbin/* /scripts/

# Configure scripts
#   Ensure scripts are executable
RUN chmod a+x /scripts/* && \
#   Ensure scripts are line-encoded for unix/linux
    dos2unix /scripts/* && \
#   Remove "reboot" and "shutdown" binaries from the container (we will replace with symlinks to scripts)
    rm -f /sbin/reboot && rm -f /sbin/shutdown && \
#   Create symlinks in bin path ("/usr/local/sbin")
    ln -sf /scripts/homeseer /usr/local/sbin/homeseer && \
    ln -sf /scripts/reboot /usr/local/sbin/reboot && \
    ln -sf /scripts/shutdown /usr/local/sbin/shutdown && \
    ln -sf /scripts/poweroff /usr/local/sbin/poweroff

# Configure timezone
RUN if [ ! -e /etc/localtime ]; then \
      ln -sf /usr/share/zoneinfo/UTC /etc/localtime; \
    fi && \
    chown homeseer:homeseer /etc/localtime /etc/timezone

# Copy avahi config, then configure DBUS and AVAHI
COPY base/etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf
RUN mkdir -p /var/lib/dbus /var/run/dbus /var/run/avahi-daemon && \
    chown messagebus:messagebus /var/run/dbus && \
    chown avahi:avahi /var/run/avahi-daemon && \
    chown homeseer:homeseer /etc/avahi/avahi-daemon.conf && \
    chown homeseer:homeseer /var/lib/dbus && \
    chown homeseer:homeseer /var/run/dbus

# Expose ports
EXPOSE 80 10200 10300 10401 11000

# Define volume
VOLUME ["/homeseer"]

# Download HomeSeer
RUN mkdir -p /homeseer && \
    chown homeseer:homeseer /homeseer && \
    wget -O /homeseer.tar.gz "$HOMESEER_DOWNLOAD_URL"

# Set user and working directory
USER homeseer
WORKDIR /homeseer
ENTRYPOINT ["/usr/local/sbin/homeseer"]