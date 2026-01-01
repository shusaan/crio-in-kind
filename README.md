# CRI-O in KIND

Build custom KIND node images with CRI-O container runtime instead of containerd. **Automatically supports the last 3 stable Kubernetes versions with the latest CRI-O release.**

## Overview

This repository provides the necessary files to create Kubernetes in Docker (KIND) clusters that use CRI-O as the container runtime instead of the default containerd. Images are automatically built and published via GitHub Actions for multiple Kubernetes versions.

## 🚀 Quick Start

### Using Pre-built Images (Recommended)

```bash
# Use latest Kubernetes version with latest CRI-O
kind create cluster \
  --name my-crio-cluster \
  --image ghcr.io/shusaan/crio-in-kind:latest \
  --config kind-crio.yaml

# Or use specific Kubernetes version with latest CRI-O
kind create cluster \
  --name my-crio-cluster \
  --image ghcr.io/shusaan/crio-in-kind:v1.35.0 \
  --config kind-crio.yaml
```

### Verify CRI-O Runtime

```bash
# Check container runtime
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
# Expected output: cri-o://1.34.x
```

## 📦 Available Images

### Current Support Matrix

**CRI-O Version**: Always latest stable release  
**Kubernetes Versions**: Last 3 stable releases (automatically updated)

### Image Tags

#### Primary Tags (Kubernetes Version)
- `ghcr.io/shusaan/crio-in-kind:v1.35.0` - Latest CRI-O with Kubernetes v1.35.0
- `ghcr.io/shusaan/crio-in-kind:v1.34.3` - Latest CRI-O with Kubernetes v1.34.3  
- `ghcr.io/shusaan/crio-in-kind:v1.33.7` - Latest CRI-O with Kubernetes v1.33.7

#### Version-Specific Tags
- `ghcr.io/shusaan/crio-in-kind:v1.34` - Latest CRI-O version tag
- `ghcr.io/shusaan/crio-in-kind:v1.34-k8s-v1.35.0` - Full version specification
- `ghcr.io/shusaan/crio-in-kind:latest` - Latest CRI-O with latest Kubernetes

#### Development Tags
- `ghcr.io/shusaan/crio-in-kind:main` - Latest from main branch
- `ghcr.io/shusaan/crio-in-kind:sha-xxxxxxx` - Specific commit builds

## 🔧 Usage Examples

### Method 1: Helper Script (Easiest)

```bash
# Set cluster name (optional)
export CLUSTER_NAME=my-crio-cluster

# Create cluster with latest versions
./scripts/create-kind-cluster.sh
```

### Method 2: Manual KIND Commands

```bash
# Latest versions
kind create cluster \
  --name crio-test \
  --image ghcr.io/shusaan/crio-in-kind:latest \
  --config kind-crio.yaml

# Specific Kubernetes version
kind create cluster \
  --name crio-k8s-134 \
  --image ghcr.io/shusaan/crio-in-kind:v1.34.3 \
  --config kind-crio.yaml
```

### Method 3: Local Build

```bash
# Build locally (uses latest versions)
./scripts/build-kind-image.sh

# Create cluster with local image
kind create cluster \
  --name local-crio \
  --image kindnode/crio:v1.34 \
  --config kind-crio.yaml
```

## 🧪 Testing & Examples

### Test with Sample Application

```bash
# Deploy test application
kubectl apply -f examples/httpbin.yaml

# Port forward to test
kubectl port-forward svc/httpbin 8000:8000

# Test in another terminal
curl -X GET localhost:8000/get
```

### Test Kubernetes 1.34+ Features

```bash
# Test Docker image name blocking (only works properly with CRI-O)
kubectl apply -f examples/test-image-name-blocking.yaml

# This should fail with CRI-O in K8s 1.34+ (short names blocked)
kubectl run test-short --image=nginx:latest

# This should work (full registry name)
kubectl run test-full --image=docker.io/library/nginx:latest
```

## ⚙️ Configuration

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

### Prerequisites

- KIND installed ([installation guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- Docker or Podman
- kubectl

## 🔄 Automatic Updates

This repository automatically:
- **Monitors** CRI-O and Kubernetes releases weekly
- **Builds** images for the last 3 stable Kubernetes versions
- **Publishes** multi-architecture images (linux/amd64, linux/arm64)
- **Creates** GitHub releases with SHA256 digests
- **Updates** documentation with supported versions

See [RELEASE_AUTOMATION.md](RELEASE_AUTOMATION.md) for details.

## 🛠️ Development

### Local Development

```bash
# Build image locally (uses latest versions)
./scripts/build-kind-image.sh

# Create test cluster
./scripts/create-kind-cluster.sh

# Test with sample app
kubectl apply -f examples/httpbin.yaml
```

### Contributing

1. Fork the repository
2. Create your feature branch
3. Test with different versions
4. Ensure CI/CD pipeline passes
5. Submit a pull request

## 🔍 Troubleshooting

### Common Issues

1. **Build fails**: Ensure Docker is running and you have internet access
2. **KIND cluster fails to start**: Check that the image was built/pulled successfully
3. **CRI-O not working**: Verify the socket configuration in kind-crio.yaml
4. **Image migration fails**: Ensure sufficient disk space and proper privileges

### Debugging Commands

```bash
# Check if image exists
docker images | grep ghcr.io/shusaan/crio-in-kind

# Check KIND cluster status
kind get clusters

# Check node status
kubectl get nodes -o wide

# Check CRI-O logs in KIND node
docker exec -it <kind-node-name> journalctl -u crio

# Check container runtime version
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
```

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

- [CRI-O GitHub Documentation](https://github.com/cri-o/cri-o/blob/main/tutorials/crio-in-kind.md/)
- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Container Runtime Interface](https://kubernetes.io/docs/concepts/architecture/cri/)
- [OpenSUSE CRI-O Packages](https://download.opensuse.org/repositories/isv:/cri-o:/)
