ARG KUBERNETES_VERSION=v1.31.0
FROM kindest/node:${KUBERNETES_VERSION}

ARG CRIO_VERSION
# Extract minor version from CRIO_VERSION (e.g., v1.34 -> 1.34)
ARG CRIO_VERSION_MINOR

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing Packages ..." \
    && apt-get clean \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common vim gnupg curl \
    && echo "Installing cri-o from pkgs.k8s.io repository..." \
    && echo "Using CRI-O version: $CRIO_VERSION" \
    && echo "Using CRI-O minor version: $CRIO_VERSION_MINOR" \
    && curl -fsSL "https://pkgs.k8s.io/addons:/cri-o:/stable:/v${CRIO_VERSION_MINOR}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/v${CRIO_VERSION_MINOR}/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --option=Dpkg::Options::=--force-confdef install -y cri-o podman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && systemctl disable containerd \
    && systemctl enable crio