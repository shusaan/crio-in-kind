ARG KUBERNETES_VERSION=v1.31.0
FROM kindest/node:${KUBERNETES_VERSION}

ARG CRIO_VERSION
ARG OS=xUbuntu_22.04

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing Packages ..." \
    && apt-get clean \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common vim gnupg curl \
    && echo "Installing cri-o from isv:cri-o:stable repository..." \
    && echo "Using CRI-O version: $CRIO_VERSION" \
    && echo "Using OS: $OS" \
    && curl -fsSL "https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/$OS/Release.key" | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/$OS/ /" | tee /etc/apt/sources.list.d/cri-o.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --option=Dpkg::Options::=--force-confdef install -y cri-o podman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && systemctl disable containerd \
    && systemctl enable crio