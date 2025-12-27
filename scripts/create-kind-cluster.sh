#!/bin/bash

# Script to create KIND cluster with CRI-O runtime
set -e

CRIO_VERSION=${CRIO_VERSION:-v1.33}
CLUSTER_NAME=${CLUSTER_NAME:-crio-test}
IMAGE_NAME=${IMAGE_NAME:-kindnode/crio:${CRIO_VERSION}}

echo "Creating KIND cluster with CRI-O runtime..."
echo "Image: $IMAGE_NAME"
echo "Cluster: $CLUSTER_NAME"

# Check if KIND is installed
if ! command -v kind &> /dev/null; then
    echo "Error: KIND is not installed. Please install KIND first."
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Create cluster
kind create cluster \
    --name "$CLUSTER_NAME" \
    --image "$IMAGE_NAME" \
    --config ./kind-crio.yaml

echo "Cluster created successfully!"
echo "To use the cluster:"
echo "  kubectl cluster-info --context kind-$CLUSTER_NAME"
echo ""
echo "To test with httpbin:"
echo "  kubectl apply -f examples/httpbin.yaml"
echo "  kubectl port-forward svc/httpbin 8000:8000"
echo "  curl -X GET localhost:8000/get"