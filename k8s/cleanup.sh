#!/bin/bash

# Kubernetes Cleanup Script for E-commerce System
# This script removes all deployed components from the Kubernetes cluster

set -e

echo "=========================================="
echo "E-commerce System Kubernetes Cleanup"
echo "=========================================="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed."
    exit 1
fi

echo "WARNING: This will delete all resources in the 'ecommerce' namespace."
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Deleting all resources..."

# Delete frontend components
echo "Deleting frontend components..."
kubectl delete -f frontend/frontend-service.yaml --ignore-not-found=true
kubectl delete -f frontend/frontend-deployment.yaml --ignore-not-found=true
kubectl delete -f frontend/frontend-configmap.yaml --ignore-not-found=true

# Delete backend components
echo "Deleting backend components..."
kubectl delete -f backend/backend-service.yaml --ignore-not-found=true
kubectl delete -f backend/backend-deployment.yaml --ignore-not-found=true
kubectl delete -f backend/backend-configmap.yaml --ignore-not-found=true
kubectl delete -f backend/backend-secret.yaml --ignore-not-found=true

# Delete database components
echo "Deleting database components..."
kubectl delete -f database/mysql-service.yaml --ignore-not-found=true
kubectl delete -f database/mysql-statefulset.yaml --ignore-not-found=true
kubectl delete -f database/mysql-pvc.yaml --ignore-not-found=true
kubectl delete -f database/mysql-initdb-configmap.yaml --ignore-not-found=true
kubectl delete -f database/mysql-configmap.yaml --ignore-not-found=true
kubectl delete -f database/mysql-secret.yaml --ignore-not-found=true

# Delete namespace
echo "Deleting namespace..."
kubectl delete -f namespace.yaml --ignore-not-found=true

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
