# Multi-stage build for CRI-O
FROM golang:1.23-bullseye AS builder

# CRI-O version to build
ARG CRIO_VERSION=v1.30.0

# Install dependencies
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

# Clone CRI-O repository and checkout specified version
RUN git clone https://github.com/cri-o/cri-o.git . && \
    git checkout ${CRIO_VERSION}

# Build CRI-O
RUN make && ls -la bin/

# Runtime stage
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    iptables \
    runc \
    conmon \
    crun \
    libdevmapper1.02.1 \
    libgpgme11 \
    libassuan0 \
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