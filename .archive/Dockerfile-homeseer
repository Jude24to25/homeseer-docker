#########################################
# HOMESEER (V4) LINUX - DOCKERFILE
#########################################
ARG DOCKER_IMAGE
ARG DOCKER_IMAGE_BASE
ARG HOMESEER_DOWNLOAD_URL
ARG LABEL_SCHEMA_URL
ARG LABEL_SCHEMA_VCS_URL
ARG LABEL_SCHEMA_VENDOR
ARG BUILD_PLATFORMS
ARG VERSION
ARG BUILDDATE
ARG DEBIAN_FRONTEND=noninteractive
FROM ${DOCKER_IMAGE_BASE}:latest

# docker container image labels
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILDDATE
LABEL org.label-schema.name="${DOCKER_IMAGE}"
LABEL org.label-schema.description="HomeSeer Docker Image"
LABEL org.label-schema.url="$LABEL_SCHEMA_URL"
LABEL org.label-schema.vcs-url="$LABEL_SCHEMA_VCS_URL"
LABEL org.label-schema.vendor="$LABEL_SCHEMA_VENDOR"
LABEL org.label-schema.version=$VERSION

RUN echo "========================================================="
RUN echo "  BUILDING DOCKER HOMESEER ($VERSION) IMAGE FOR: $BUILD_PLATFORMS"
RUN echo "========================================================="

# Configure runtime environment variables
ENV HOMESEER_VERSION="$VERSION" \
    TZ=America/Los_Angeles \
    LANG=en_US.UTF-8

# Download and install HomeSeer Linux
RUN wget -O /homeseer.tar.gz "$HOMESEER_DOWNLOAD_URL" && \
    tar -xzf /homeseer.tar.gz -C /homeseer && \
    rm /homeseer.tar.gz

USER homeseer
WORKDIR /homeseer
ENTRYPOINT ["/usr/local/sbin/homeseer"]