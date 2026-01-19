ARG KIND_VERSION=v1.31.0
FROM kindest/node:${KIND_VERSION}

ARG CRIO_VERSION=v1.34

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Prevent systemd service startup during package installation
RUN printf '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Install dependencies
# hadolint ignore=DL3008
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add CRI-O repository
# Extract major.minor version from CRIO_VERSION (e.g., v1.35.0 -> v1.35)
RUN CRIO_REPO_VERSION="${CRIO_VERSION%.*}" && \
    curl -fsSL "https://download.opensuse.org/repositories/isv:/cri-o:/stable:/${CRIO_REPO_VERSION}/deb/Release.key" \
    | gpg --dearmor -o /etc/apt/keyrings/cri-o.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/cri-o.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/${CRIO_REPO_VERSION}/deb/ /" \
    > /etc/apt/sources.list.d/cri-o.list

# Install cri-o using force options and manual dependency resolution
WORKDIR /tmp
# hadolint ignore=SC2046
RUN apt-get update && \
    apt-get download cri-o $(apt-cache depends --recurse --no-recommends --no-suggests cri-o | grep "^\w" | sort -u) && \
    dpkg -i --force-all ./*.deb || true && \
    apt-get install -f -y --no-install-recommends && \
    rm -f ./*.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clean up and switch from containerd to CRI-O
RUN rm -f /usr/sbin/policy-rc.d && \
    sed -i 's/containerd/crio/g' /etc/crictl.yaml && \
    systemctl disable containerd && \
    systemctl enable crio

# Create necessary directories for CRI-O
RUN mkdir -p /var/lib/crio /var/log/crio /etc/crio/crio.conf.d