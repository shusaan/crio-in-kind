# CRI-O in KIND

Build custom KIND node images with CRI-O container runtime instead of containerd.

## Overview

This repository provides the necessary files to create Kubernetes in Docker (KIND) clusters that use CRI-O as the container runtime instead of the default containerd. Images are automatically built and published via GitHub Actions.

## Prerequisites

- KIND installed ([installation guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- Docker or Podman
- kubectl

## How to Use with KIND

### Method 1: Using Pre-built Images (Recommended)

The easiest way is to use our pre-built images from GitHub Container Registry:

```bash
# Create KIND cluster with CRI-O image
kind create cluster \
  --name my-crio-cluster \
  --image ghcr.io/shusaan/crio-in-kind:v1.33 \
  --config kind-crio.yaml
```

### Method 2: Using Local Build

If you prefer to build the image locally:

```bash
# Build the image
./scripts/build-kind-image.sh

# Create cluster with local image
kind create cluster \
  --name my-crio-cluster \
  --image kindnode/crio:v1.33 \
  --config kind-crio.yaml
```

### Method 3: Using Helper Script

Use our convenience script that handles everything:

```bash
# Set cluster name (optional)
export CLUSTER_NAME=my-crio-cluster

# Create cluster
./scripts/create-kind-cluster.sh
```

### Verify CRI-O Runtime

After creating the cluster, verify it's using CRI-O:

```bash
# Check cluster info
kubectl cluster-info --context kind-my-crio-cluster

# Verify container runtime
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
# Expected output: cri-o://1.33.x
```

### Available Image Tags

Our images are available with multiple tags:

- `ghcr.io/shusaan/crio-in-kind:v1.33` - Specific CRI-O version
- `ghcr.io/shusaan/crio-in-kind:latest` - Latest stable build
- `ghcr.io/shusaan/crio-in-kind:main` - Latest from main branch

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

# Test Docker image name blocking (K8s 1.34+)
kubectl apply -f examples/test-image-name-blocking.yaml
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

### Workflows Explained

We use two separate GitHub Actions workflows for different purposes:

#### `test.yml` - Testing & Validation
- **Purpose**: Fast feedback and quality checks
- **Triggers**: Every push and pull request
- **Actions**: Build validation, Dockerfile linting
- **Speed**: Fast (no registry operations)
- **Security**: Safe for external PRs

#### `build-and-push.yml` - Production Build & Deploy
- **Purpose**: Build and publish production images
- **Triggers**: Main/develop branches and tags only
- **Actions**: Full build, registry push, security scanning
- **Speed**: Slower (includes scanning and publishing)
- **Security**: Restricted to trusted branches

#### `version-update.yml` - Automated Version Management
- **Purpose**: Automatically update CRI-O and Kubernetes versions
- **Triggers**: Weekly schedule (Mondays) + manual dispatch
- **Actions**: Check latest versions, update files, create PR
- **Branch**: Creates `automated-version-update` branch
- **Automation**: Fully automated version maintenance

This separation provides both **fast feedback** for developers and **secure publishing** for production images.

### Branch Strategy

The project follows a simple branching strategy:

- **`main`** - Production branch, triggers image builds and pushes
- **`develop`** - Development branch, triggers image builds and pushes  
- **`automated-version-update`** - Auto-created by version update workflow
- **`feature/*`** - Feature branches, only trigger tests (no image push)
- **`fix/*`** - Bug fix branches, only trigger tests (no image push)

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

1. **Base Image**: Starts with official `kindest/node:v1.31.0` (configurable)
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
│   ├── httpbin.yaml                    # Sample Kubernetes application
│   └── test-image-name-blocking.yaml  # Test for K8s 1.34+ image name blocking
└── README.md                  # This file
```

## Configuration

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

# Test Docker image name blocking behavior (K8s 1.34+)
kubectl apply -f examples/test-image-name-blocking.yaml
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
- **Kubernetes**: v1.29+ (configurable via KIND node version)
- **KIND**: Latest stable (uses kindest/node images)
- **Container Images**: Automatically migrated from containerd to CRI-O

## Why Use CRI-O with KIND?

### Benefits Over Default KIND Images

Official KIND images use **containerd** as the container runtime, but this project provides **CRI-O** as an alternative with several advantages:

#### **Performance Benefits**
- **Faster startup times** - CRI-O has less overhead than containerd
- **Lower memory usage** - More lightweight runtime footprint
- **Better resource utilization** - Optimized for Kubernetes workloads

#### **Security Advantages**
- **Reduced attack surface** - CRI-O is purpose-built for Kubernetes only
- **Enhanced security features** - Built-in security policies and controls
- **OCI compliance** - Follows Open Container Initiative standards strictly

#### **Production Alignment**
- **Real-world testing** - Many production environments use CRI-O
- **Red Hat/OpenShift compatibility** - Same runtime used in OpenShift
- **Enterprise readiness** - Test your apps with production-grade runtime

#### **Development Benefits**
- **Debugging capabilities** - Better tooling for container inspection
- **Kubernetes-native** - Designed specifically for Kubernetes CRI
- **Simplified architecture** - No Docker daemon complexity

### When to Use This Image

✅ **Use CRI-O KIND image when:**
- **Testing runtime-specific behaviors** - CRI-O vs containerd differences
- **Kubernetes security features** - Testing features that behave differently with CRI-O
- **Docker image name blocking validation** - K8s 1.34+ blocks short image names only with CRI-O
- **Production environment simulation** - Many production clusters use CRI-O
- **OpenShift/Red Hat compatibility** - Same runtime used in OpenShift
- **Container runtime debugging** - Investigating CRI-O specific issues
- **Security policy testing** - CRI-O has different security implementations
- **Performance benchmarking** - Comparing CRI-O vs containerd performance

❌ **Use standard KIND when:**
- Just learning Kubernetes basics
- Need Docker-in-Docker functionality
- Using Docker-specific features
- Working with legacy Docker workflows

### Real-World Use Case: Docker Image Name Blocking

A perfect example of why you need CRI-O for testing:

**Problem**: Kubernetes 1.34+ implements short Docker image name blocking for security, but this feature behaves differently between container runtimes.

**With KIND (containerd)**: Short image names like `nginx:latest` may still be allowed
**With CRI-O KIND**: Proper image name blocking behavior matches production - short names are blocked

```bash
# Test Docker image name blocking with CRI-O
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-short-image
spec:
  containers:
  - name: test
    image: nginx:latest  # This should be blocked in K8s 1.34+ with CRI-O
EOF

# With CRI-O in K8s 1.34+: Pod creation fails (short name blocked)
# With containerd: May still allow short names (inconsistent behavior)

# The correct way in K8s 1.34+:
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-full-image
spec:
  containers:
  - name: test
    image: docker.io/library/nginx:latest  # Full name always works
EOF
```

## How to Use with KIND

## References

- [CRI-O Official Documentation](https://cri-o.io/)
- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Container Runtime Interface](https://kubernetes.io/docs/concepts/architecture/cri/)
- [OpenSUSE CRI-O Packages](https://download.opensuse.org/repositories/isv:/cri-o:/)
