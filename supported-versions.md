# Supported Versions

This repository automatically builds CRI-O KIND images for the **last 3 stable Kubernetes versions** using the **latest CRI-O release**.

## Current Support Matrix

The pipeline automatically detects and builds images for:

- **CRI-O Version**: Always latest stable release from [cri-o/cri-o](https://github.com/cri-o/cri-o/releases)
- **Kubernetes Versions**: Last 3 stable releases from [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/releases)

## Image Tags

### Primary Tags
- `ghcr.io/[username]/crio-in-kind:v1.35.0` - Kubernetes version with latest CRI-O
- `ghcr.io/[username]/crio-in-kind:v1.34.3` - Kubernetes version with latest CRI-O  
- `ghcr.io/[username]/crio-in-kind:v1.33.7` - Kubernetes version with latest CRI-O

### Version-Specific Tags
- `ghcr.io/[username]/crio-in-kind:v1.34-k8s-v1.35.0` - Full version specification
- `ghcr.io/[username]/crio-in-kind:v1.34` - Latest CRI-O with latest Kubernetes
- `ghcr.io/[username]/crio-in-kind:latest` - Always latest CRI-O with latest Kubernetes

## Usage Examples

```bash
# Use latest Kubernetes version with latest CRI-O
kind create cluster --image ghcr.io/[username]/crio-in-kind:latest

# Use specific Kubernetes version with latest CRI-O
kind create cluster --image ghcr.io/[username]/crio-in-kind:v1.34.3

# Use specific CRI-O version with latest Kubernetes
kind create cluster --image ghcr.io/[username]/crio-in-kind:v1.34
```

## Automatic Updates

The pipeline automatically:
1. **Checks weekly** for new CRI-O releases
2. **Builds images** for the last 3 stable Kubernetes versions
3. **Creates releases** with SHA256 digests for reproducibility
4. **Updates documentation** with supported versions

## Version Lifecycle

- **New Kubernetes release**: Automatically added, oldest version dropped
- **New CRI-O release**: All supported Kubernetes versions rebuilt with new CRI-O
- **Support window**: Always maintains 3 most recent stable Kubernetes versions

This ensures users always have access to the latest CRI-O features while maintaining compatibility with recent Kubernetes versions.