#!/bin/bash

# Traffic Switching Script for Blue-Green Deployment
# Usage: ./switch-traffic.sh <blue|green>
# Example: ./switch-traffic.sh green

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Validate arguments
if [ $# -ne 1 ]; then
    print_error "Usage: $0 <blue|green>"
    print_error "Example: $0 green"
    exit 1
fi

TARGET_ENV=$1

# Validate environment
if [ "$TARGET_ENV" != "blue" ] && [ "$TARGET_ENV" != "green" ]; then
    print_error "Environment must be 'blue' or 'green'"
    exit 1
fi

# Determine current environment
CURRENT_BACKEND=$(kubectl get service backend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown")
CURRENT_FRONTEND=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown")

print_info "Current traffic routing:"
print_info "  Backend: $CURRENT_BACKEND"
print_info "  Frontend: $CURRENT_FRONTEND"
print_info ""
print_info "Target environment: $TARGET_ENV"

# Check if target environment is already active
if [ "$CURRENT_BACKEND" == "$TARGET_ENV" ] && [ "$CURRENT_FRONTEND" == "$TARGET_ENV" ]; then
    print_warn "Traffic is already routed to $TARGET_ENV environment"
    exit 0
fi

# Verify target deployments exist and are ready
print_step "Verifying target deployments..."

if ! kubectl get deployment backend-$TARGET_ENV -n $NAMESPACE &> /dev/null; then
    print_error "Deployment backend-$TARGET_ENV does not exist"
    exit 1
fi

if ! kubectl get deployment frontend-$TARGET_ENV -n $NAMESPACE &> /dev/null; then
    print_error "Deployment frontend-$TARGET_ENV does not exist"
    exit 1
fi

# Check if deployments are ready
BACKEND_READY=$(kubectl get deployment backend-$TARGET_ENV -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
BACKEND_DESIRED=$(kubectl get deployment backend-$TARGET_ENV -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

FRONTEND_READY=$(kubectl get deployment frontend-$TARGET_ENV -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
FRONTEND_DESIRED=$(kubectl get deployment frontend-$TARGET_ENV -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

print_info "Backend $TARGET_ENV: $BACKEND_READY/$BACKEND_DESIRED ready"
print_info "Frontend $TARGET_ENV: $FRONTEND_READY/$FRONTEND_READY ready"

if [ "$BACKEND_READY" != "$BACKEND_DESIRED" ] || [ "$FRONTEND_READY" != "$FRONTEND_DESIRED" ]; then
    print_error "Target deployments are not fully ready"
    print_error "Please wait for all pods to be ready before switching traffic"
    exit 1
fi

# Confirm with user
print_warn "This will switch ALL production traffic to the $TARGET_ENV environment"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Traffic switch cancelled"
    exit 0
fi

# Switch backend service
print_step "Switching backend service to $TARGET_ENV..."
kubectl patch service backend-service -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"backend\",\"version\":\"$TARGET_ENV\"}}}"

# Verify backend switch
sleep 2
NEW_BACKEND=$(kubectl get service backend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
if [ "$NEW_BACKEND" == "$TARGET_ENV" ]; then
    print_info "Backend service switched successfully ✓"
else
    print_error "Backend service switch failed"
    exit 1
fi

# Switch frontend service
print_step "Switching frontend service to $TARGET_ENV..."
kubectl patch service frontend-service -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"version\":\"$TARGET_ENV\"}}}"

# Verify frontend switch
sleep 2
NEW_FRONTEND=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
if [ "$NEW_FRONTEND" == "$TARGET_ENV" ]; then
    print_info "Frontend service switched successfully ✓"
else
    print_error "Frontend service switch failed"
    exit 1
fi

# Verify endpoints
print_step "Verifying service endpoints..."
sleep 3

BACKEND_ENDPOINTS=$(kubectl get endpoints backend-service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
FRONTEND_ENDPOINTS=$(kubectl get endpoints frontend-service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)

print_info "Backend service endpoints: $BACKEND_ENDPOINTS"
print_info "Frontend service endpoints: $FRONTEND_ENDPOINTS"

if [ "$BACKEND_ENDPOINTS" -eq 0 ] || [ "$FRONTEND_ENDPOINTS" -eq 0 ]; then
    print_error "No endpoints found for services!"
    print_error "Traffic switch may have failed. Consider rolling back."
    exit 1
fi

# Success
print_info ""
print_info "═══════════════════════════════════════════════════════"
print_info "Traffic switch completed successfully! ✓"
print_info "═══════════════════════════════════════════════════════"
print_info ""
print_info "Current traffic routing:"
print_info "  Backend: $NEW_BACKEND"
print_info "  Frontend: $NEW_FRONTEND"
print_info ""
print_info "Next steps:"
print_info "1. Monitor the application for errors:"
print_info "   kubectl logs -n $NAMESPACE -l version=$TARGET_ENV --tail=100 -f"
print_info ""
print_info "2. Check metrics and error rates"
print_info ""
print_info "3. If issues occur, rollback immediately:"
if [ "$TARGET_ENV" == "blue" ]; then
    print_info "   ./rollback.sh green"
else
    print_info "   ./rollback.sh blue"
fi
print_info ""
print_info "4. Once stable, scale down the old environment:"
if [ "$TARGET_ENV" == "blue" ]; then
    print_info "   kubectl scale deployment backend-green frontend-green -n $NAMESPACE --replicas=0"
else
    print_info "   kubectl scale deployment backend-blue frontend-blue -n $NAMESPACE --replicas=0"
fi
