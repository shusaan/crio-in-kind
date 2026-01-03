#!/bin/bash

set -euo pipefail

CRIO_VERSION=${CRIO_VERSION:-v1.34}
KUBERNETES_VERSION=${KUBERNETES_VERSION:-v1.31.0}
TARGET="kindnode/crio:$CRIO_VERSION"
INTERMEDIATE="${TARGET}-tmp"

echo "Building intermediate image $INTERMEDIATE ..."
echo "Using CRI-O version: $CRIO_VERSION"
echo "Using Kubernetes version: $KUBERNETES_VERSION"

docker build \
    --build-arg CRIO_VERSION=$CRIO_VERSION \
    --build-arg KUBERNETES_VERSION=$KUBERNETES_VERSION \
    -t $INTERMEDIATE .

echo "Building final image $TARGET ..."

# Run the intermediate image in the background
docker run --privileged --rm -d --name crio-builder --entrypoint sleep $INTERMEDIATE infinity

function cleanup {
    docker kill crio-builder 2>/dev/null || true
}

# Remove the crio-builder container on exit
trap cleanup EXIT

# Start crio & containerd daemons
docker exec -d crio-builder containerd
docker exec -d crio-builder crio

# Wait for daemons to start
sleep 15

# Migrate the pinned kube-* images from containerd to cri-o
docker exec crio-builder bash -c 'for IMG in $(ctr -n k8s.io images list -q | grep "registry.k8s.io/kube-"); do echo "Migrating $IMG ..." && ctr -n k8s.io image export --platform "linux/amd64" - "$IMG" | podman load; done'

# Commit the final image, restoring the original entrypoint
docker commit --change 'ENTRYPOINT [ "/usr/local/bin/entrypoint", "/sbin/init" ]' crio-builder $TARGET

echo "Finished building image: $TARGET"