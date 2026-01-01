ARG KUBERNETES_VERSION=v1.31.0
FROM kindest/node:${KUBERNETES_VERSION}

ARG CRIO_VERSION
# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing Packages ..." \
    && apt-get clean \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common vim gnupg curl wget \
    && echo "Installing cri-o from GitHub releases..." \
    && echo "Using CRI-O version: $CRIO_VERSION" \
    && CRIO_VERSION_CLEAN=$(echo "$CRIO_VERSION" | sed 's/^v//') \
    && echo "Using CRI-O clean version: $CRIO_VERSION_CLEAN" \
    && ARCH=$(dpkg --print-architecture) \
    && echo "Architecture: $ARCH" \
    && wget -O /tmp/crio.tar.gz "https://github.com/cri-o/cri-o/releases/download/$CRIO_VERSION/crio-$CRIO_VERSION_CLEAN.linux.$ARCH.tar.gz" \
    && tar -xzf /tmp/crio.tar.gz -C /tmp \
    && cd /tmp/crio-$CRIO_VERSION_CLEAN \
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