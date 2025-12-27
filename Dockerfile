# Multi-stage build for CRI-O
FROM golang:1.25-trixie AS builder

# CRI-O version to build
ARG CRIO_VERSION=v1.31.2

# Install dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    pkg-config \
    libgpgme-dev \
    libassuan-dev \
    libbtrfs-dev \
    libdevmapper-dev \
    libseccomp-dev \
    libsystemd-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /go/src/github.com/cri-o/cri-o

# Clone and build in separate steps for better caching
RUN git clone --depth 1 --branch ${CRIO_VERSION} https://github.com/cri-o/cri-o.git .

# Build CRI-O with optimizations
RUN make BUILDTAGS="containers_image_ostree_stub containers_image_openpgp" && \
    ls -la bin/

# Runtime stage - use matching Trixie base for glibc compatibility
FROM debian:trixie-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    iptables \
    runc \
    libdevmapper1.02.1 \
    libgpgme11 \
    libassuan9 \
    libseccomp2 \
    libsystemd0 \
    libbtrfs0 \
    && rm -rf /var/lib/apt/lists/*

# Copy CRI-O binaries from builder
COPY --from=builder /go/src/github.com/cri-o/cri-o/bin/ /usr/local/bin/

# Debug: Check what libraries crio needs
RUN ldd /usr/local/bin/crio || true

# Create necessary directories
RUN mkdir -p /etc/crio /var/lib/containers/storage /var/run/crio

# Create a basic CRI-O configuration
RUN echo '[crio]' > /etc/crio/crio.conf && \
    echo 'storage_driver = "overlay"' >> /etc/crio/crio.conf && \
    echo 'storage_option = ["overlay.mount_program=/usr/bin/fuse-overlayfs"]' >> /etc/crio/crio.conf

# Expose CRI-O socket
VOLUME ["/var/run/crio"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/crio"]
CMD ["--config", "/etc/crio/crio.conf"]