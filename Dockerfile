ARG KIND_VERSION=v1.31.0
FROM kindest/node:${KIND_VERSION}

ARG CRIO_VERSION=v1.31
ARG PROJECT_PATH=prerelease:/$CRIO_VERSION

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN echo "Installing Packages ..." \
    && apt-get clean \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common vim gnupg \
    && echo "Installing cri-o ..." \
    && curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/$PROJECT_PATH/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/$PROJECT_PATH/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --option=Dpkg::Options::=--force-confdef install -y cri-o podman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && systemctl disable containerd \
    && systemctl enable crio