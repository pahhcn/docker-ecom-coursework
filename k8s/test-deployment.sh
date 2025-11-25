#!/bin/bash

# Test script for Kubernetes deployment
# This script verifies that all components are deployed correctly

set -e

echo "=========================================="
echo "Testing Kubernetes Deployment"
echo "=========================================="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi
echo "✓ kubectl is installed"

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi
echo "✓ Cluster is accessible"
echo ""

# Check namespace
echo "Checking namespace..."
if kubectl get namespace ecommerce &> /dev/null; then
    echo "✓ Namespace 'ecommerce' exists"
else
    echo "❌ Namespace 'ecommerce' does not exist"
    exit 1
fi
echo ""

# Check database components
echo "Checking database components..."
kubectl get statefulset mysql -n ecommerce &> /dev/null && echo "✓ MySQL StatefulSet exists" || echo "❌ MySQL StatefulSet missing"
kubectl get service mysql-service -n ecommerce &> /dev/null && echo "✓ MySQL Service exists" || echo "❌ MySQL Service missing"
kubectl get pvc mysql-pvc -n ecommerce &> /dev/null && echo "✓ MySQL PVC exists" || echo "❌ MySQL PVC missing"
kubectl get secret mysql-secret -n ecommerce &> /dev/null && echo "✓ MySQL Secret exists" || echo "❌ MySQL Secret missing"
kubectl get configmap mysql-config -n ecommerce &> /dev/null && echo "✓ MySQL ConfigMap exists" || echo "❌ MySQL ConfigMap missing"
echo ""

# Check backend components
echo "Checking backend components..."
kubectl get deployment backend -n ecommerce &> /dev/null && echo "✓ Backend Deployment exists" || echo "❌ Backend Deployment missing"
kubectl get service backend-service -n ecommerce &> /dev/null && echo "✓ Backend Service exists" || echo "❌ Backend Service missing"
kubectl get secret backend-secret -n ecommerce &> /dev/null && echo "✓ Backend Secret exists" || echo "❌ Backend Secret missing"
kubectl get configmap backend-config -n ecommerce &> /dev/null && echo "✓ Backend ConfigMap exists" || echo "❌ Backend ConfigMap missing"
echo ""

# Check frontend components
echo "Checking frontend components..."
kubectl get deployment frontend -n ecommerce &> /dev/null && echo "✓ Frontend Deployment exists" || echo "❌ Frontend Deployment missing"
kubectl get service frontend-service -n ecommerce &> /dev/null && echo "✓ Frontend Service exists" || echo "❌ Frontend Service missing"
kubectl get configmap frontend-config -n ecommerce &> /dev/null && echo "✓ Frontend ConfigMap exists" || echo "❌ Frontend ConfigMap missing"
echo ""

# Check pod status
echo "Checking pod status..."
echo ""
kubectl get pods -n ecommerce
echo ""

# Check if all pods are running
MYSQL_READY=$(kubectl get pods -n ecommerce -l app=mysql -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
BACKEND_READY=$(kubectl get deployment backend -n ecommerce -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "False")
FRONTEND_READY=$(kubectl get deployment frontend -n ecommerce -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "False")

echo "Pod Readiness Status:"
if [ "$MYSQL_READY" = "True" ]; then
    echo "✓ MySQL is ready"
else
    echo "❌ MySQL is not ready"
fi

if [ "$BACKEND_READY" = "True" ]; then
    echo "✓ Backend is ready"
else
    echo "❌ Backend is not ready"
fi

if [ "$FRONTEND_READY" = "True" ]; then
    echo "✓ Frontend is ready"
else
    echo "❌ Frontend is not ready"
fi
echo ""

# Test API connectivity (if backend is ready)
if [ "$BACKEND_READY" = "True" ]; then
    echo "Testing API connectivity..."
    
    # Get a backend pod name
    BACKEND_POD=$(kubectl get pods -n ecommerce -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$BACKEND_POD" ]; then
        echo "Testing from backend pod: $BACKEND_POD"
        
        # Test database connectivity
        if kubectl exec -n ecommerce "$BACKEND_POD" -- sh -c "nc -zv mysql-service 3306" &> /dev/null; then
            echo "✓ Backend can connect to database"
        else
            echo "❌ Backend cannot connect to database"
        fi
    fi
fi
echo ""

# Display services
echo "=========================================="
echo "Services"
echo "=========================================="
kubectl get services -n ecommerce
echo ""

# Display access information
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""

if kubectl config current-context | grep -q "minikube"; then
    echo "You are using minikube. To access the frontend, run:"
    echo "  minikube service frontend-service -n ecommerce"
else
    echo "To access the frontend, use port-forward:"
    echo "  kubectl port-forward -n ecommerce service/frontend-service 8080:80"
    echo "  Then open: http://localhost:8080"
fi

echo ""
echo "To access the backend API, use port-forward:"
echo "  kubectl port-forward -n ecommerce service/backend-service 8080:8080"
echo "  Then test: curl http://localhost:8080/api/products"

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="
