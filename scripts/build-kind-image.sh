#!/bin/bash

set -euo pipefail

CRIO_VERSION=${CRIO_VERSION:-v1.33}
TARGET="kindnode/crio:$CRIO_VERSION"
INTERMEDIATE="${TARGET}-tmp"

echo "Building intermediate image $INTERMEDIATE ..."
docker build --build-arg CRIO_VERSION=$CRIO_VERSION -t $INTERMEDIATE .

echo "Building final image $TARGET ..."

# Run the intermediate image in the background
docker run --privileged --rm -d --name crio-builder --entrypoint sleep $INTERMEDIATE infinity

function cleanup {
    docker kill crio-builder
}

# Remove the crio-builder container on exit
trap cleanup EXIT

# Start crio & containerd daemons
docker exec -d crio-builder containerd
docker exec -d crio-builder crio

# Migrate the pinned kube-* images from containerd to cri-o
docker exec crio-builder bash -c 'for IMG in $(ctr -n k8s.io images list -q | grep "registry.k8s.io/kube-"); do echo "Migrating $IMG ..." && ctr -n k8s.io image export --platform "linux/amd64" - "$IMG" | podman load; done'

# Commit the final image, restoring the original entrypoint
docker commit --change 'ENTRYPOINT [ "/usr/local/bin/entrypoint", "/sbin/init" ]' crio-builder $TARGET

echo "Finished building image: $TARGET"