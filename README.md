# crio-in-kind

A containerized CRI-O implementation for Kubernetes in Docker (KIND) environments.

## Quick Start

### Building the Image

```bash
# Build locally
docker build -t crio-in-kind:latest .

# Or use docker-compose
docker-compose build
```

### Running with Docker Compose

```bash
# Start CRI-O service
docker-compose up -d

# Test the build
docker-compose --profile test run crio-test
```

### Manual Docker Run

```bash
docker run -d \
  --name crio-container \
  --privileged \
  -v /var/run/crio:/var/run/crio \
  -v /var/lib/containers:/var/lib/containers \
  crio-in-kind:latest
```

## CI/CD

This repository includes GitHub Actions workflows:

- **build-and-push.yml**: Builds and pushes images to GitHub Container Registry
- **test.yml**: Tests the Docker build and runs security scans

### Registry

Images are automatically pushed to `ghcr.io/[username]/crio-in-kind` on:
- Push to main/develop branches
- Tagged releases
- Pull requests (build only, no push)

## Configuration

The Dockerfile builds CRI-O from source and includes:
- Multi-stage build for optimized image size
- Runtime dependencies (runc, conmon, crun)
- Default CRI-O configuration
- Security scanning with Trivy

## Development

```bash
# Test build locally
docker build -t crio-test .

# Run tests
docker run --rm crio-test --version
```
