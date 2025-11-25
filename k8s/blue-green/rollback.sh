#!/bin/bash

# Rollback Script for Blue-Green Deployment
# Usage: ./rollback.sh <blue|green>
# Example: ./rollback.sh blue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ecommerce"

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
if [ $# -ne 1 ]; then
    print_error "Usage: $0 <blue|green>"
    print_error "Example: $0 blue"
    exit 1
fi

ROLLBACK_ENV=$1

# Validate environment
if [ "$ROLLBACK_ENV" != "blue" ] && [ "$ROLLBACK_ENV" != "green" ]; then
    print_error "Environment must be 'blue' or 'green'"
    exit 1
fi

# Get current environment
CURRENT_BACKEND=$(kubectl get service backend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown")
CURRENT_FRONTEND=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown")

print_warn "═══════════════════════════════════════════════════════"
print_warn "ROLLBACK INITIATED"
print_warn "═══════════════════════════════════════════════════════"
print_info "Current environment: $CURRENT_BACKEND"
print_info "Rolling back to: $ROLLBACK_ENV"
print_warn "═══════════════════════════════════════════════════════"

# Check if rollback environment is different from current
if [ "$CURRENT_BACKEND" == "$ROLLBACK_ENV" ] && [ "$CURRENT_FRONTEND" == "$ROLLBACK_ENV" ]; then
    print_warn "Already running on $ROLLBACK_ENV environment"
    exit 0
fi

# Verify rollback deployments exist and are ready
print_info "Verifying rollback deployments..."

if ! kubectl get deployment backend-$ROLLBACK_ENV -n $NAMESPACE &> /dev/null; then
    print_error "Deployment backend-$ROLLBACK_ENV does not exist"
    exit 1
fi

if ! kubectl get deployment frontend-$ROLLBACK_ENV -n $NAMESPACE &> /dev/null; then
    print_error "Deployment frontend-$ROLLBACK_ENV does not exist"
    exit 1
fi

# Check if deployments are ready
BACKEND_READY=$(kubectl get deployment backend-$ROLLBACK_ENV -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
BACKEND_DESIRED=$(kubectl get deployment backend-$ROLLBACK_ENV -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

FRONTEND_READY=$(kubectl get deployment frontend-$ROLLBACK_ENV -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
FRONTEND_DESIRED=$(kubectl get deployment frontend-$ROLLBACK_ENV -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

print_info "Backend $ROLLBACK_ENV: $BACKEND_READY/$BACKEND_DESIRED ready"
print_info "Frontend $ROLLBACK_ENV: $FRONTEND_READY/$FRONTEND_DESIRED ready"

# If deployments are scaled down, scale them up
if [ "$BACKEND_DESIRED" -eq 0 ] || [ "$FRONTEND_DESIRED" -eq 0 ]; then
    print_warn "Rollback environment is scaled down. Scaling up..."
    kubectl scale deployment backend-$ROLLBACK_ENV -n $NAMESPACE --replicas=2
    kubectl scale deployment frontend-$ROLLBACK_ENV -n $NAMESPACE --replicas=2
    
    print_info "Waiting for deployments to be ready..."
    kubectl rollout status deployment/backend-$ROLLBACK_ENV -n $NAMESPACE --timeout=300s
    kubectl rollout status deployment/frontend-$ROLLBACK_ENV -n $NAMESPACE --timeout=300s
fi

if [ "$BACKEND_READY" != "$BACKEND_DESIRED" ] || [ "$FRONTEND_READY" != "$FRONTEND_DESIRED" ]; then
    print_warn "Rollback deployments are not fully ready, but proceeding with rollback..."
fi

# Perform rollback (switch traffic)
print_info "Switching traffic to $ROLLBACK_ENV environment..."

# Switch backend service
kubectl patch service backend-service -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"backend\",\"version\":\"$ROLLBACK_ENV\"}}}"

# Switch frontend service
kubectl patch service frontend-service -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"version\":\"$ROLLBACK_ENV\"}}}"

# Verify switch
sleep 3
NEW_BACKEND=$(kubectl get service backend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
NEW_FRONTEND=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}')

if [ "$NEW_BACKEND" == "$ROLLBACK_ENV" ] && [ "$NEW_FRONTEND" == "$ROLLBACK_ENV" ]; then
    print_info ""
    print_info "═══════════════════════════════════════════════════════"
    print_info "ROLLBACK COMPLETED SUCCESSFULLY ✓"
    print_info "═══════════════════════════════════════════════════════"
    print_info "Traffic has been switched back to: $ROLLBACK_ENV"
    print_info ""
    print_info "Next steps:"
    print_info "1. Verify the application is working correctly"
    print_info "2. Monitor logs: kubectl logs -n $NAMESPACE -l version=$ROLLBACK_ENV --tail=100 -f"
    print_info "3. Investigate the issue with the failed deployment"
else
    print_error "Rollback failed!"
    print_error "Backend: $NEW_BACKEND (expected: $ROLLBACK_ENV)"
    print_error "Frontend: $NEW_FRONTEND (expected: $ROLLBACK_ENV)"
    exit 1
fi
