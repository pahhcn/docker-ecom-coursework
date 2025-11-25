#!/bin/bash

# Test Script for Blue-Green Deployment
# This script tests the blue-green deployment strategy

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

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

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

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test function
run_test() {
    local test_name=$1
    local test_command=$2
    
    print_test "$test_name"
    if eval "$test_command" &> /dev/null; then
        print_pass "$test_name"
        return 0
    else
        print_fail "$test_name"
        return 1
    fi
}

print_info "═══════════════════════════════════════════════════════"
print_info "Blue-Green Deployment Test Suite"
print_info "═══════════════════════════════════════════════════════"
print_info ""

# Test 1: Check if namespace exists
print_test "Test 1: Namespace exists"
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_pass "Namespace $NAMESPACE exists"
else
    print_fail "Namespace $NAMESPACE does not exist"
fi

# Test 2: Check if blue deployments exist
print_test "Test 2: Blue deployments exist"
BLUE_BACKEND_EXISTS=$(kubectl get deployment backend-blue -n $NAMESPACE &> /dev/null && echo "yes" || echo "no")
BLUE_FRONTEND_EXISTS=$(kubectl get deployment frontend-blue -n $NAMESPACE &> /dev/null && echo "yes" || echo "no")

if [ "$BLUE_BACKEND_EXISTS" == "yes" ] && [ "$BLUE_FRONTEND_EXISTS" == "yes" ]; then
    print_pass "Blue deployments exist"
else
    print_fail "Blue deployments missing (backend: $BLUE_BACKEND_EXISTS, frontend: $BLUE_FRONTEND_EXISTS)"
fi

# Test 3: Check if green deployments exist
print_test "Test 3: Green deployments exist"
GREEN_BACKEND_EXISTS=$(kubectl get deployment backend-green -n $NAMESPACE &> /dev/null && echo "yes" || echo "no")
GREEN_FRONTEND_EXISTS=$(kubectl get deployment frontend-green -n $NAMESPACE &> /dev/null && echo "yes" || echo "no")

if [ "$GREEN_BACKEND_EXISTS" == "yes" ] && [ "$GREEN_FRONTEND_EXISTS" == "yes" ]; then
    print_pass "Green deployments exist"
else
    print_fail "Green deployments missing (backend: $GREEN_BACKEND_EXISTS, frontend: $GREEN_FRONTEND_EXISTS)"
fi

# Test 4: Check if services exist
print_test "Test 4: Services exist"
BACKEND_SERVICE_EXISTS=$(kubectl get service backend-service -n $NAMESPACE &> /dev/null && echo "yes" || echo "no")
FRONTEND_SERVICE_EXISTS=$(kubectl get service frontend-service -n $NAMESPACE &> /dev/null && echo "yes" || echo "no")

if [ "$BACKEND_SERVICE_EXISTS" == "yes" ] && [ "$FRONTEND_SERVICE_EXISTS" == "yes" ]; then
    print_pass "Services exist"
else
    print_fail "Services missing (backend: $BACKEND_SERVICE_EXISTS, frontend: $FRONTEND_SERVICE_EXISTS)"
fi

# Test 5: Check current traffic routing
print_test "Test 5: Traffic routing is configured"
CURRENT_BACKEND=$(kubectl get service backend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "none")
CURRENT_FRONTEND=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "none")

if [ "$CURRENT_BACKEND" != "none" ] && [ "$CURRENT_FRONTEND" != "none" ]; then
    print_pass "Traffic routing configured (backend: $CURRENT_BACKEND, frontend: $CURRENT_FRONTEND)"
else
    print_fail "Traffic routing not configured"
fi

# Test 6: Check if blue pods are running (if blue is active)
if [ "$CURRENT_BACKEND" == "blue" ] || [ "$CURRENT_FRONTEND" == "blue" ]; then
    print_test "Test 6: Blue pods are running"
    BLUE_BACKEND_READY=$(kubectl get deployment backend-blue -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    BLUE_FRONTEND_READY=$(kubectl get deployment frontend-blue -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    if [ "$BLUE_BACKEND_READY" -gt 0 ] && [ "$BLUE_FRONTEND_READY" -gt 0 ]; then
        print_pass "Blue pods are running (backend: $BLUE_BACKEND_READY, frontend: $BLUE_FRONTEND_READY)"
    else
        print_fail "Blue pods not running (backend: $BLUE_BACKEND_READY, frontend: $BLUE_FRONTEND_READY)"
    fi
fi

# Test 7: Check if green pods are running (if green is active)
if [ "$CURRENT_BACKEND" == "green" ] || [ "$CURRENT_FRONTEND" == "green" ]; then
    print_test "Test 7: Green pods are running"
    GREEN_BACKEND_READY=$(kubectl get deployment backend-green -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    GREEN_FRONTEND_READY=$(kubectl get deployment frontend-green -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    if [ "$GREEN_BACKEND_READY" -gt 0 ] && [ "$GREEN_FRONTEND_READY" -gt 0 ]; then
        print_pass "Green pods are running (backend: $GREEN_BACKEND_READY, frontend: $GREEN_FRONTEND_READY)"
    else
        print_fail "Green pods not running (backend: $GREEN_BACKEND_READY, frontend: $GREEN_FRONTEND_READY)"
    fi
fi

# Test 8: Check service endpoints
print_test "Test 8: Service endpoints are configured"
BACKEND_ENDPOINTS=$(kubectl get endpoints backend-service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
FRONTEND_ENDPOINTS=$(kubectl get endpoints frontend-service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)

if [ "$BACKEND_ENDPOINTS" -gt 0 ] && [ "$FRONTEND_ENDPOINTS" -gt 0 ]; then
    print_pass "Service endpoints configured (backend: $BACKEND_ENDPOINTS, frontend: $FRONTEND_ENDPOINTS)"
else
    print_fail "Service endpoints not configured (backend: $BACKEND_ENDPOINTS, frontend: $FRONTEND_ENDPOINTS)"
fi

# Test 9: Verify pod labels match service selectors
print_test "Test 9: Pod labels match service selectors"
if [ "$CURRENT_BACKEND" != "none" ]; then
    BACKEND_PODS=$(kubectl get pods -n $NAMESPACE -l app=backend,version=$CURRENT_BACKEND --no-headers 2>/dev/null | wc -l)
    if [ "$BACKEND_PODS" -gt 0 ]; then
        print_pass "Backend pod labels match service selector"
    else
        print_fail "Backend pod labels don't match service selector"
    fi
fi

if [ "$CURRENT_FRONTEND" != "none" ]; then
    FRONTEND_PODS=$(kubectl get pods -n $NAMESPACE -l app=frontend,version=$CURRENT_FRONTEND --no-headers 2>/dev/null | wc -l)
    if [ "$FRONTEND_PODS" -gt 0 ]; then
        print_pass "Frontend pod labels match service selector"
    else
        print_fail "Frontend pod labels don't match service selector"
    fi
fi

# Test 10: Check if both environments can coexist
print_test "Test 10: Both environments can coexist"
TOTAL_BACKEND_PODS=$(kubectl get pods -n $NAMESPACE -l app=backend --no-headers 2>/dev/null | wc -l)
TOTAL_FRONTEND_PODS=$(kubectl get pods -n $NAMESPACE -l app=frontend --no-headers 2>/dev/null | wc -l)

if [ "$TOTAL_BACKEND_PODS" -ge 2 ] && [ "$TOTAL_FRONTEND_PODS" -ge 2 ]; then
    print_pass "Multiple environment pods can coexist"
else
    print_warn "Only one environment is running (backend pods: $TOTAL_BACKEND_PODS, frontend pods: $TOTAL_FRONTEND_PODS)"
fi

# Summary
print_info ""
print_info "═══════════════════════════════════════════════════════"
print_info "Test Summary"
print_info "═══════════════════════════════════════════════════════"
print_info "Tests Passed: $TESTS_PASSED"
print_info "Tests Failed: $TESTS_FAILED"
print_info ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_info "All tests passed! ✓"
    exit 0
else
    print_error "Some tests failed!"
    exit 1
fi
