# Multi-stage build for CRI-O
FROM golang:1.21-bullseye AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
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

# Clone CRI-O repository
RUN git clone https://github.com/cri-o/cri-o.git . && \
    git checkout main

# Build CRI-O
RUN make

# Runtime stage
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    iptables \
    runc \
    conmon \
    crun \
    && rm -rf /var/lib/apt/lists/*

# Copy CRI-O binaries from builder
COPY --from=builder /go/src/github.com/cri-o/cri-o/bin/crio /usr/local/bin/
COPY --from=builder /go/src/github.com/cri-o/cri-o/bin/crio-status /usr/local/bin/

# Create necessary directories
RUN mkdir -p /etc/crio /var/lib/containers/storage /var/run/crio

# Copy default configuration
COPY --from=builder /go/src/github.com/cri-o/cri-o/crio.conf /etc/crio/
COPY --from=builder /go/src/github.com/cri-o/cri-o/crictl.yaml /etc/

# Expose CRI-O socket
VOLUME ["/var/run/crio"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/crio"]
CMD ["--config", "/etc/crio/crio.conf"]