#!/bin/bash

# Blue-Green Deployment Script
# Usage: ./deploy-blue-green.sh <blue|green> <version>
# Example: ./deploy-blue-green.sh green v2.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ecommerce"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate arguments
if [ $# -ne 2 ]; then
    print_error "Usage: $0 <blue|green> <version>"
    print_error "Example: $0 green v2.0.0"
    exit 1
fi

ENVIRONMENT=$1
VERSION=$2

# Validate environment
if [ "$ENVIRONMENT" != "blue" ] && [ "$ENVIRONMENT" != "green" ]; then
    print_error "Environment must be 'blue' or 'green'"
    exit 1
fi

print_info "Starting blue-green deployment"
print_info "Environment: $ENVIRONMENT"
print_info "Version: $VERSION"
print_info "Namespace: $NAMESPACE"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    print_error "Namespace $NAMESPACE does not exist"
    print_error "Please create it first: kubectl create namespace $NAMESPACE"
    exit 1
fi

# Check if required resources exist (configmaps, secrets)
print_info "Checking prerequisites..."
if ! kubectl get configmap backend-config -n $NAMESPACE &> /dev/null; then
    print_warn "backend-config ConfigMap not found. Please ensure it exists."
fi

if ! kubectl get secret backend-secret -n $NAMESPACE &> /dev/null; then
    print_warn "backend-secret Secret not found. Please ensure it exists."
fi

if ! kubectl get configmap frontend-config -n $NAMESPACE &> /dev/null; then
    print_warn "frontend-config ConfigMap not found. Please ensure it exists."
fi

# Update image versions in deployment files
print_info "Updating image versions to $VERSION..."

# Create temporary files with updated versions
BACKEND_DEPLOYMENT="$SCRIPT_DIR/backend-${ENVIRONMENT}-deployment.yaml"
FRONTEND_DEPLOYMENT="$SCRIPT_DIR/frontend-${ENVIRONMENT}-deployment.yaml"

# Update backend image version
sed "s|ecommerce-backend:v[0-9.]*|ecommerce-backend:$VERSION|g" "$BACKEND_DEPLOYMENT" > /tmp/backend-${ENVIRONMENT}-deployment.yaml

# Update frontend image version
sed "s|ecommerce-frontend:v[0-9.]*|ecommerce-frontend:$VERSION|g" "$FRONTEND_DEPLOYMENT" > /tmp/frontend-${ENVIRONMENT}-deployment.yaml

# Deploy backend
print_info "Deploying backend-$ENVIRONMENT..."
kubectl apply -f /tmp/backend-${ENVIRONMENT}-deployment.yaml

# Deploy frontend
print_info "Deploying frontend-$ENVIRONMENT..."
kubectl apply -f /tmp/frontend-${ENVIRONMENT}-deployment.yaml

# Wait for deployments to be ready
print_info "Waiting for backend-$ENVIRONMENT to be ready..."
kubectl rollout status deployment/backend-$ENVIRONMENT -n $NAMESPACE --timeout=300s

print_info "Waiting for frontend-$ENVIRONMENT to be ready..."
kubectl rollout status deployment/frontend-$ENVIRONMENT -n $NAMESPACE --timeout=300s

# Verify pods are running
print_info "Verifying pods..."
BACKEND_READY=$(kubectl get deployment backend-$ENVIRONMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
FRONTEND_READY=$(kubectl get deployment frontend-$ENVIRONMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')

print_info "Backend $ENVIRONMENT ready replicas: $BACKEND_READY"
print_info "Frontend $ENVIRONMENT ready replicas: $FRONTEND_READY"

# Test the deployment
print_info "Testing $ENVIRONMENT deployment..."

# Get a backend pod
BACKEND_POD=$(kubectl get pods -n $NAMESPACE -l app=backend,version=$ENVIRONMENT -o jsonpath='{.items[0].metadata.name}')

if [ -n "$BACKEND_POD" ]; then
    print_info "Testing backend health endpoint..."
    if kubectl exec -n $NAMESPACE $BACKEND_POD -- wget -q -O- http://localhost:8080/actuator/health &> /dev/null; then
        print_info "Backend health check passed ✓"
    else
        print_warn "Backend health check failed"
    fi
fi

# Get a frontend pod
FRONTEND_POD=$(kubectl get pods -n $NAMESPACE -l app=frontend,version=$ENVIRONMENT -o jsonpath='{.items[0].metadata.name}')

if [ -n "$FRONTEND_POD" ]; then
    print_info "Testing frontend health endpoint..."
    if kubectl exec -n $NAMESPACE $FRONTEND_POD -- wget -q -O- http://localhost:80/health &> /dev/null; then
        print_info "Frontend health check passed ✓"
    else
        print_warn "Frontend health check failed"
    fi
fi

# Clean up temporary files
rm -f /tmp/backend-${ENVIRONMENT}-deployment.yaml
rm -f /tmp/frontend-${ENVIRONMENT}-deployment.yaml

print_info "Deployment complete!"
print_info ""
print_info "Next steps:"
print_info "1. Test the $ENVIRONMENT environment:"
print_info "   kubectl port-forward -n $NAMESPACE deployment/backend-$ENVIRONMENT 8081:8080"
print_info "   kubectl port-forward -n $NAMESPACE deployment/frontend-$ENVIRONMENT 8080:80"
print_info ""
print_info "2. When ready to switch traffic, run:"
print_info "   ./switch-traffic.sh $ENVIRONMENT"
print_info ""
print_info "3. To rollback, run:"
print_info "   ./rollback.sh <previous-environment>"
