ARG KIND_VERSION=v1.31.0
FROM kindest/node:${KIND_VERSION}

ARG CRIO_VERSION=v1.34

# Add CRI-O repository using OpenSUSE Kubernetes repository
ARG PROJECT_PATH=stable:/v1.35
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing Packages ..." \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       software-properties-common vim gnupg curl \
    && echo "Installing cri-o ..." \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/${PROJECT_PATH}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/${PROJECT_PATH}/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       -o Dpkg::Options::="--force-confdef" \
       -o Dpkg::Options::="--force-confold" \
       cri-o podman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's|unix:///run/containerd/containerd.sock|unix:///var/run/crio/crio.sock|g' /etc/crictl.yaml

# Create necessary directories for CRI-O
RUN mkdir -p /var/lib/crio /var/log/crio /etc/crio/crio.conf.d