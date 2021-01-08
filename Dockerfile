#
# makemkv Dockerfile
#
# https://github.com/jlesage/docker-makemkv
#

# Build MakeMKV.
FROM ubuntu:bionic
COPY makemkv-builder /tmp/makemkv-builder
RUN /tmp/makemkv-builder/builder/build.sh /tmp/

# Build YAD.  The one from the Alpine repo doesn't support the multi-progress
# feature.
FROM alpine:3.12
ARG YAD_VERSION=0.40.0
ARG YAD_URL=https://downloads.sourceforge.net/project/yad-dialog/yad-${YAD_VERSION}.tar.xz
RUN apk --no-cache add \
    build-base \
    curl \
    gtk+2.0-dev \
    intltool
RUN \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download.
    mkdir /tmp/yad && \
    curl -# -L "${YAD_URL}" | tar xJ --strip 1 -C /tmp/yad && \
    # Compile.
    cd /tmp/yad && \
    ./configure && \
    make -j$(nproc) && \
    strip src/yad

# Pull base image.
FROM hydrohs/xpra-base

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG CCEXTRACTOR_VERSION=0.88

# Define software download URLs.
ARG CCEXTRACTOR_URL=https://github.com/CCExtractor/ccextractor/archive/v${CCEXTRACTOR_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Install MakeMKV.
COPY --from=0 /tmp/makemkv-install /

# Install Java 8.
RUN \
    add-pkg openjdk8-jre-base && \
    # Removed uneeded stuff.
    rm -r \
        /usr/lib/jvm/java-1.8-openjdk/bin \
        /usr/lib/jvm/java-1.8-openjdk/lib \
        /usr/lib/jvm/java-1.8-openjdk/jre/lib/ext \
        && \
    # Cleanup.
    rm -rf /tmp/* /tmp/.[!.]*

# Compile and install ccextractor.
RUN \
    add-pkg --virtual build-dependencies \
        build-base \
        cmake \
        zlib-dev \
        curl \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download and extract.
    mkdir /tmp/ccextractor && \
    curl -# -L "${CCEXTRACTOR_URL}" | tar xz --strip 1 -C /tmp/ccextractor && \
    # Compile.
    mkdir ccextractor/build && \
    cd ccextractor/build && \
    cmake ../src && \
    make && \
    cd ../../ && \
    # Install.
    cp ccextractor/build/ccextractor /usr/bin/ && \
    strip /usr/bin/ccextractor && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install YAD.
COPY --from=1 /tmp/yad/src/yad /usr/bin/
RUN add-pkg gtk+2.0

# Install dependencies.
RUN \
    add-pkg \
        wget \
        sed \
        findutils \
        util-linux \
        lsscsi

# Add files.
COPY rootfs/ /

# Update the default configuration file with the latest beta key.
RUN /opt/makemkv/bin/makemkv-update-beta-key /defaults/settings.conf

# Set environment variables.
ENV APP_NAME="MakeMKV" \
    MAKEMKV_KEY="BETA"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]