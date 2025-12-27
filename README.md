# CRI-O in KIND

Build custom KIND node images with CRI-O container runtime instead of containerd.

## Overview

This repository provides the necessary files to create Kubernetes in Docker (KIND) clusters that use CRI-O as the container runtime instead of the default containerd. Images are automatically built and published via GitHub Actions.

## Prerequisites

- KIND installed ([installation guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- Docker or Podman
- kubectl

## Quick Start

### Option 1: Use Pre-built Image (Recommended)

```bash
# Pull the pre-built image from GitHub Container Registry
docker pull ghcr.io/[username]/crio-in-kind:v1.33

# Create KIND cluster with pre-built image
kind create cluster \
  --name crio-test \
  --image ghcr.io/[username]/crio-in-kind:v1.33 \
  --config ./kind-crio.yaml
```

### Option 2: Build Locally

```bash
# Set CRI-O version (default: v1.33)
export CRIO_VERSION=v1.33

# Build the KIND node image with CRI-O
./scripts/build-kind-image.sh
```

### Create KIND Cluster

```bash
# Using the create script (works with both pre-built and local images)
./scripts/create-kind-cluster.sh

# Or manually:
kind create cluster \
  --name crio-test \
  --image kindnode/crio:v1.33 \
  --config ./kind-crio.yaml
```

### Verify CRI-O Runtime

```bash
# Check cluster info
kubectl cluster-info --context kind-crio-test

# Verify container runtime
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
# Should output: cri-o://1.33.x
```

### Test with Sample Application

```bash
# Deploy test application
kubectl apply -f examples/httpbin.yaml

# Port forward to test
kubectl port-forward svc/httpbin 8000:8000

# Test in another terminal
curl -X GET localhost:8000/get
```

## CI/CD

This repository includes automated GitHub Actions workflows:

- **build-and-push.yml**: Builds KIND CRI-O images and pushes to GitHub Container Registry
- **test.yml**: Tests the Docker build process and runs Dockerfile linting

### Build Process

The CI/CD pipeline performs a sophisticated build process:

1. **Builds intermediate image** from Dockerfile (installs CRI-O packages)
2. **Runs privileged container** to start both containerd and CRI-O daemons
3. **Migrates Kubernetes images** from containerd storage to CRI-O storage
4. **Commits final image** with proper KIND entrypoint restored
5. **Tags and pushes** to GitHub Container Registry

### Registry

Images are automatically pushed to `ghcr.io/[username]/crio-in-kind` on:
- Push to main/develop branches
- Tagged releases
- Pull requests (build only, no push)

### Available Tags

- `ghcr.io/[username]/crio-in-kind:v1.33` - CRI-O version tag
- `ghcr.io/[username]/crio-in-kind:latest` - Latest build from main branch
- `ghcr.io/[username]/crio-in-kind:main` - Main branch builds
- `ghcr.io/[username]/crio-in-kind:sha-xxxxxxx` - Specific commit builds

## How It Works

### KIND Node Image Build Process

The build process creates a fully functional KIND node with CRI-O:

1. **Base Image**: Starts with official `kindest/node:latest`
2. **Install CRI-O**: Adds CRI-O packages from OpenSUSE repositories
3. **Configure Runtime**: 
   - Switches crictl from containerd to CRI-O
   - Disables containerd service
   - Enables CRI-O service
4. **Image Migration**: Migrates pre-loaded Kubernetes images from containerd to CRI-O storage
5. **Final Image**: Commits the configured image with proper KIND entrypoint

### Files Structure

```
├── Dockerfile                   # KIND node with CRI-O installation
├── .github/workflows/
│   ├── build-and-push.yml      # CI/CD pipeline for building and pushing
│   └── test.yml                # Testing and linting workflow
├── scripts/
│   ├── build-kind-image.sh     # Local build script (for development)
│   └── create-kind-cluster.sh  # Script to create KIND cluster
├── kind-crio.yaml              # KIND cluster configuration
├── examples/
│   └── httpbin.yaml           # Sample Kubernetes application
└── README.md                  # This file
```

## Configuration

### CRI-O Version

Change the CRI-O version by updating the environment variable in `.github/workflows/build-and-push.yml`:

```yaml
env:
  CRIO_VERSION: v1.33  # Change this to desired version
```

For local builds:

```bash
export CRIO_VERSION=v1.32  # or any supported version
./scripts/build-kind-image.sh
```

### KIND Cluster Configuration

The `kind-crio.yaml` file configures the cluster to use CRI-O socket:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      criSocket: unix:///var/run/crio/crio.sock
```

## Development

### Local Development

```bash
# Build image locally
export CRIO_VERSION=v1.33
./scripts/build-kind-image.sh

# Create test cluster
./scripts/create-kind-cluster.sh

# Test with sample app
kubectl apply -f examples/httpbin.yaml
```

### Contributing

1. Fork the repository
2. Create your feature branch
3. Test with different CRI-O versions
4. Ensure CI/CD pipeline passes
5. Submit a pull request

## Troubleshooting

### Common Issues

1. **Build fails**: Ensure Docker is running and you have internet access
2. **KIND cluster fails to start**: Check that the image was built/pulled successfully
3. **CRI-O not working**: Verify the socket configuration in kind-crio.yaml
4. **Image migration fails**: Ensure sufficient disk space and proper privileges

### Debugging Commands

```bash
# Check if image exists
docker images | grep kindnode/crio
# or for pre-built images
docker images | grep ghcr.io

# Check KIND cluster status
kind get clusters

# Check node status
kubectl get nodes -o wide

# Check CRI-O logs in KIND node
docker exec -it <kind-node-name> journalctl -u crio

# Check container runtime
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
```

## Supported Versions

- **CRI-O**: v1.30+ (configurable via environment variable)
- **KIND**: Latest stable
- **Kubernetes**: Compatible with KIND's supported versions
- **Container Images**: Automatically migrated from containerd to CRI-O

## References

- [CRI-O Official Documentation](https://cri-o.io/)
- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Container Runtime Interface](https://kubernetes.io/docs/concepts/architecture/cri/)
- [OpenSUSE CRI-O Packages](https://download.opensuse.org/repositories/isv:/cri-o:/)
