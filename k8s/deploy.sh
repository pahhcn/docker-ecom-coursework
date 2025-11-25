#!/bin/bash

# Kubernetes Deployment Script for E-commerce System
# This script deploys all components to a Kubernetes cluster

set -e

echo "=========================================="
echo "E-commerce System Kubernetes Deployment"
echo "=========================================="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✓ kubectl is installed and cluster is accessible"
echo ""

# Create namespace
echo "Step 1: Creating namespace..."
kubectl apply -f namespace.yaml
echo "✓ Namespace created"
echo ""

# Deploy database components
echo "Step 2: Deploying database components..."
kubectl apply -f database/mysql-secret.yaml
kubectl apply -f database/mysql-configmap.yaml
kubectl apply -f database/mysql-initdb-configmap.yaml
kubectl apply -f database/mysql-pvc.yaml
kubectl apply -f database/mysql-statefulset.yaml
kubectl apply -f database/mysql-service.yaml
echo "✓ Database components deployed"
echo ""

# Wait for database to be ready
echo "Step 3: Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n ecommerce --timeout=300s
echo "✓ Database is ready"
echo ""

# Deploy backend components
echo "Step 4: Deploying backend components..."
kubectl apply -f backend/backend-secret.yaml
kubectl apply -f backend/backend-configmap.yaml
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml
echo "✓ Backend components deployed"
echo ""

# Wait for backend to be ready
echo "Step 5: Waiting for backend to be ready..."
kubectl wait --for=condition=available deployment/backend -n ecommerce --timeout=300s
echo "✓ Backend is ready"
echo ""

# Deploy frontend components
echo "Step 6: Deploying frontend components..."
kubectl apply -f frontend/frontend-configmap.yaml
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml
echo "✓ Frontend components deployed"
echo ""

# Wait for frontend to be ready
echo "Step 7: Waiting for frontend to be ready..."
kubectl wait --for=condition=available deployment/frontend -n ecommerce --timeout=300s
echo "✓ Frontend is ready"
echo ""

# Display deployment status
echo "=========================================="
echo "Deployment Status"
echo "=========================================="
echo ""
kubectl get all -n ecommerce
echo ""

# Display service endpoints
echo "=========================================="
echo "Service Endpoints"
echo "=========================================="
echo ""
kubectl get services -n ecommerce
echo ""

# Get frontend service URL
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""
echo "To access the application:"
echo ""

# Check if running on minikube
if kubectl config current-context | grep -q "minikube"; then
    echo "You are using minikube. Run the following command to access the frontend:"
    echo "  minikube service frontend-service -n ecommerce"
else
    FRONTEND_IP=$(kubectl get service frontend-service -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    if [ "$FRONTEND_IP" = "pending" ] || [ -z "$FRONTEND_IP" ]; then
        echo "LoadBalancer IP is pending. Run the following command to check status:"
        echo "  kubectl get service frontend-service -n ecommerce"
        echo ""
        echo "For local testing, you can use port-forward:"
        echo "  kubectl port-forward -n ecommerce service/frontend-service 8080:80"
        echo "  Then access: http://localhost:8080"
    else
        echo "Frontend URL: http://$FRONTEND_IP"
        echo "Backend API: http://$FRONTEND_IP/api/products"
    fi
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
