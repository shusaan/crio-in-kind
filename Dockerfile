ARG KIND_VERSION=v1.31.0
FROM kindest/node:${KIND_VERSION}

ARG CRIO_VERSION=v1.33.7
# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing Packages ..." \
    && apt-get clean \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common vim gnupg curl wget \
    && echo "Installing cri-o from Google Cloud Storage..." \
    && echo "Using CRI-O version: $CRIO_VERSION" \
    && ARCH=$(dpkg --print-architecture) \
    && echo "Architecture: $ARCH" \
    && wget -O /tmp/crio.tar.gz "https://storage.googleapis.com/cri-o/artifacts/cri-o.$ARCH.$CRIO_VERSION.tar.gz" \
    && tar -xzf /tmp/crio.tar.gz -C /tmp \
    && cd /tmp/crio-* \
    && ./install \
    && rm -rf /tmp/crio* \
    && echo "Installing podman..." \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y podman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && systemctl disable containerd \
    && systemctl enable crio