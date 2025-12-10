#!/bin/bash

#############################################################################
# Build Canary Image Helper Script
# 
# Quickly build a new version for testing with auto_canary.sh
#############################################################################

# Get Docker registry user from environment or use default
DOCKER_REGISTRY_USER="${DOCKER_REGISTRY_USER:-dhruvk321}"

VERSION="${1:-v1.1}"
IMAGE_NAME="$DOCKER_REGISTRY_USER/infin8:$VERSION"

echo "========================================="
echo "Building Canary Image: $IMAGE_NAME"
echo "========================================="
echo ""

# Build the image
echo "🔨 Building Docker image..."
docker build -t $IMAGE_NAME . || {
    echo "❌ Build failed!"
    exit 1
}

echo ""
echo "✅ Build successful!"
echo ""
echo "📤 Pushing to Docker Hub..."
docker push $IMAGE_NAME || {
    echo "❌ Push failed! Make sure you're logged in:"
    echo "   docker login"
    exit 1
}

echo ""
echo "========================================="
echo "✅ Image ready: $IMAGE_NAME"
echo "========================================="
echo ""
echo "Now you can run:"
echo "  ./auto_canary.sh $IMAGE_NAME"
echo ""
