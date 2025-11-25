# Blue-Green Deployment Guide

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Initial Setup](#initial-setup)
5. [Deployment Workflow](#deployment-workflow)
6. [Traffic Switching](#traffic-switching)
7. [Rollback Procedures](#rollback-procedures)
8. [Testing](#testing)
9. [Monitoring](#monitoring)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

## Overview

Blue-green deployment is a release management strategy that reduces downtime and risk by running two identical production environments called Blue and Green. At any time, only one environment serves production traffic while the other is idle or being updated.

### Key Benefits

- **Zero Downtime**: Traffic switches atomically between environments
- **Easy Rollback**: Instant rollback by switching traffic back
- **Testing in Production**: Test new version with production data before going live
- **Reduced Risk**: Problems in new version don't affect production until switch

### How It Works

1. **Blue** is currently running production (version 1.0.0)
2. Deploy new version to **Green** (version 2.0.0)
3. Test Green environment thoroughly
4. Switch traffic from Blue to Green atomically
5. Monitor Green for issues
6. If problems occur, switch back to Blue instantly
7. If stable, Blue becomes the next Green for future deployments

## Architecture

### Service Architecture

```
                    ┌─────────────────────────────┐
                    │   Kubernetes Service        │
                    │   (Traffic Router)          │
                    │                             │
                    │   selector:                 │
                    │     app: backend            │
                    │     version: blue  ◄────────┼─── Switch this label
                    └─────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Blue Deployment     │    │  Green Deployment    │
    │  (Active)            │    │  (Standby/Testing)   │
    │                      │    │                      │
    │  Image: v1.0.0       │    │  Image: v2.0.0       │
    │  Replicas: 2         │    │  Replicas: 2         │
    │  Labels:             │    │  Labels:             │
    │    app: backend      │    │    app: backend      │
    │    version: blue     │    │    version: green    │
    └──────────────────────┘    └──────────────────────┘
```

### Traffic Switching Mechanism

The Kubernetes Service uses label selectors to route traffic. By changing the `version` label in the service selector from `blue` to `green`, all traffic is instantly redirected to the new deployment.

**Before Switch:**
```yaml
selector:
  app: backend
  version: blue  # Routes to blue deployment
```

**After Switch:**
```yaml
selector:
  app: backend
  version: green  # Routes to green deployment
```

## Prerequisites

### Required Tools

- Kubernetes cluster (v1.20+)
  - Local: minikube, kind, Docker Desktop
  - Cloud: GKE, EKS, AKS
- kubectl (v1.20+)
- Docker (for building images)
- bash shell

### Required Resources

- Namespace: `ecommerce`
- ConfigMaps: `backend-config`, `frontend-config`
- Secrets: `backend-secret`
- Database: MySQL StatefulSet (already deployed)

### Resource Requirements

During blue-green deployment, you need 2x resources:

- **Backend**: 4 pods (2 blue + 2 green) = 2 CPU, 1GB RAM
- **Frontend**: 4 pods (2 blue + 2 green) = 1 CPU, 512MB RAM
- **Total**: ~3 CPU, 1.5GB RAM (temporary during deployment)

## Initial Setup

### Step 1: Verify Prerequisites

```bash
# Check cluster connection
kubectl cluster-info

# Verify namespace exists
kubectl get namespace ecommerce

# Check required resources
kubectl get configmap -n ecommerce
kubectl get secret -n ecommerce
kubectl get statefulset mysql -n ecommerce
```

### Step 2: Build and Tag Images

Build your application images with version tags:

```bash
# Build backend
cd backend
docker build -t ecommerce-backend:v1.0.0 .

# Build frontend
cd ../frontend
docker build -t ecommerce-frontend:v1.0.0 .
```

### Step 3: Deploy Initial Blue Environment

```bash
cd k8s/blue-green

# Deploy blue environment (initial production)
./deploy-blue-green.sh blue v1.0.0

# Deploy services
kubectl apply -f backend-service-blue-green.yaml
kubectl apply -f frontend-service-blue-green.yaml
```

### Step 4: Verify Initial Deployment

```bash
# Check deployments
kubectl get deployments -n ecommerce

# Check pods
kubectl get pods -n ecommerce -l version=blue

# Check services
kubectl get services -n ecommerce

# Test the application
kubectl port-forward -n ecommerce service/frontend-service 8080:80
# Open browser: http://localhost:8080
```

## Deployment Workflow

### Complete Deployment Process

```
┌─────────────────────────────────────────────────────────────┐
│                    Deployment Workflow                       │
└─────────────────────────────────────────────────────────────┘

1. Build New Version
   └─> docker build -t ecommerce-backend:v2.0.0

2. Deploy to Green
   └─> ./deploy-blue-green.sh green v2.0.0

3. Test Green Environment
   ├─> Port-forward to green pods
   ├─> Run smoke tests
   ├─> Verify health endpoints
   └─> Check logs for errors

4. Switch Traffic
   └─> ./switch-traffic.sh green

5. Monitor Production
   ├─> Watch error rates
   ├─> Check response times
   └─> Monitor logs

6. Rollback (if needed)
   └─> ./rollback.sh blue

7. Cleanup Old Version
   └─> kubectl scale deployment backend-blue --replicas=0
```

### Step-by-Step Example

#### 1. Build New Version

```bash
# Update your code
# Commit changes
git commit -am "feat: add new feature"

# Build new images
cd backend
docker build -t ecommerce-backend:v2.0.0 .

cd ../frontend
docker build -t ecommerce-frontend:v2.0.0 .
```

#### 2. Deploy to Green Environment

```bash
cd k8s/blue-green

# Deploy green with new version
./deploy-blue-green.sh green v2.0.0
```

Expected output:
```
[INFO] Starting blue-green deployment
[INFO] Environment: green
[INFO] Version: v2.0.0
[INFO] Namespace: ecommerce
[INFO] Checking prerequisites...
[INFO] Updating image versions to v2.0.0...
[INFO] Deploying backend-green...
[INFO] Deploying frontend-green...
[INFO] Waiting for backend-green to be ready...
[INFO] Waiting for frontend-green to be ready...
[INFO] Backend green ready replicas: 2
[INFO] Frontend green ready replicas: 2
[INFO] Deployment complete!
```

#### 3. Test Green Environment

```bash
# Port-forward to green backend
kubectl port-forward -n ecommerce deployment/backend-green 8081:8080 &

# Port-forward to green frontend
kubectl port-forward -n ecommerce deployment/frontend-green 8080:80 &

# Test backend health
curl http://localhost:8081/actuator/health

# Test backend API
curl http://localhost:8081/api/products

# Test frontend
curl http://localhost:8080/

# Open in browser
open http://localhost:8080

# Check logs
kubectl logs -n ecommerce -l version=green --tail=50
```

#### 4. Switch Traffic to Green

```bash
# Switch production traffic
./switch-traffic.sh green
```

You'll be prompted to confirm:
```
[WARN] This will switch ALL production traffic to the green environment
Are you sure you want to continue? (yes/no): yes
```

Expected output:
```
[STEP] Switching backend service to green...
[INFO] Backend service switched successfully ✓
[STEP] Switching frontend service to green...
[INFO] Frontend service switched successfully ✓
[INFO] Traffic switch completed successfully! ✓
```

#### 5. Monitor Production

```bash
# Watch logs
kubectl logs -n ecommerce -l version=green --tail=100 -f

# Check pod status
watch kubectl get pods -n ecommerce

# Check service endpoints
kubectl get endpoints -n ecommerce

# Monitor metrics (if Prometheus is set up)
# Check error rates, response times, etc.
```

#### 6. Rollback (if issues detected)

```bash
# Quick rollback to blue
./rollback.sh blue
```

#### 7. Cleanup Old Version

Once green is stable (after monitoring period):

```bash
# Scale down blue environment
kubectl scale deployment backend-blue -n ecommerce --replicas=0
kubectl scale deployment frontend-blue -n ecommerce --replicas=0

# Or delete blue deployments
kubectl delete deployment backend-blue frontend-blue -n ecommerce
```

## Traffic Switching

### Manual Traffic Switch

```bash
./switch-traffic.sh <blue|green>
```

### What Happens During Switch

1. **Validation**: Script verifies target environment is ready
2. **Confirmation**: User confirms the switch
3. **Backend Switch**: Updates backend-service selector
4. **Frontend Switch**: Updates frontend-service selector
5. **Verification**: Confirms endpoints are updated
6. **Success**: Reports completion

### Switch Duration

- **Actual switch**: < 1 second (atomic)
- **DNS propagation**: Immediate (ClusterIP)
- **Connection draining**: Depends on client timeout
- **Total perceived downtime**: ~0 seconds

### Verification After Switch

```bash
# Check service selectors
kubectl get service backend-service -n ecommerce -o yaml | grep -A 3 selector
kubectl get service frontend-service -n ecommerce -o yaml | grep -A 3 selector

# Check endpoints
kubectl get endpoints -n ecommerce

# Verify traffic is flowing
kubectl logs -n ecommerce -l version=green --tail=20 -f
```

## Rollback Procedures

### Quick Rollback

```bash
./rollback.sh <previous-environment>
```

### When to Rollback

- High error rates (> 5%)
- Increased response times
- Application crashes
- Database connection issues
- User-reported critical bugs

### Rollback Process

1. **Detect Issue**: Monitoring alerts or user reports
2. **Execute Rollback**: Run rollback script
3. **Verify**: Confirm old version is serving traffic
4. **Investigate**: Analyze logs and errors
5. **Fix**: Correct the issue in code
6. **Redeploy**: Try deployment again

### Automatic Rollback

For automatic rollback based on metrics, you can integrate with monitoring:

```bash
# Example: Rollback if error rate > 5%
ERROR_RATE=$(curl -s prometheus-server/api/v1/query?query=error_rate | jq '.data.result[0].value[1]')

if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
    echo "Error rate too high, rolling back..."
    ./rollback.sh blue
fi
```

## Testing

### Automated Testing

Run the test suite:

```bash
cd k8s/blue-green
./test-blue-green.sh
```

### Manual Testing Checklist

- [ ] Both blue and green deployments exist
- [ ] Services are configured correctly
- [ ] Pods are running and ready
- [ ] Health checks pass
- [ ] API endpoints respond correctly
- [ ] Frontend loads in browser
- [ ] Database connectivity works
- [ ] Traffic routing is correct
- [ ] Logs show no errors

### Smoke Tests

```bash
# Backend health
curl http://<service-ip>:8080/actuator/health

# Backend API
curl http://<service-ip>:8080/api/products

# Frontend
curl http://<service-ip>:80/

# Database connectivity (from backend pod)
kubectl exec -n ecommerce <backend-pod> -- \
  mysql -h mysql-service -u root -p<password> -e "SELECT 1"
```

## Monitoring

### Key Metrics to Monitor

1. **Error Rate**: Should remain < 1%
2. **Response Time**: p95 should be < 500ms
3. **Request Rate**: Should match expected traffic
4. **Pod Health**: All pods should be Ready
5. **Resource Usage**: CPU and memory within limits

### Monitoring Commands

```bash
# Watch pods
kubectl get pods -n ecommerce -w

# Monitor logs
kubectl logs -n ecommerce -l version=green --tail=100 -f

# Check resource usage
kubectl top pods -n ecommerce

# View events
kubectl get events -n ecommerce --sort-by='.lastTimestamp'
```

### Integration with Prometheus

If you have Prometheus set up:

```yaml
# Example alert rule
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  for: 2m
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value }} (threshold: 0.05)"
```

## Best Practices

### 1. Version Tagging

- Always use semantic versioning (v1.0.0, v2.0.0)
- Never use `latest` tag in production
- Tag images with git commit SHA for traceability

```bash
VERSION=$(git describe --tags --always)
docker build -t ecommerce-backend:$VERSION .
```

### 2. Database Migrations

- Ensure backward compatibility during transition
- New code must work with old schema
- Run migrations before deploying new version
- Use separate migration jobs if needed

### 3. Configuration Management

- Use ConfigMaps for non-sensitive config
- Use Secrets for sensitive data
- Version your configuration
- Test configuration changes in green first

### 4. Health Checks

- Implement proper readiness probes
- Don't route traffic until pods are ready
- Use liveness probes to restart unhealthy pods

### 5. Monitoring Period

- Monitor new version for at least 30 minutes
- Check error rates, response times, logs
- Have rollback plan ready
- Gradually increase confidence before cleanup

### 6. Resource Planning

- Ensure cluster has 2x capacity during deployment
- Use resource requests and limits
- Monitor resource usage
- Scale cluster if needed

### 7. Communication

- Notify team before deployment
- Have rollback owner identified
- Document deployment in change log
- Post-deployment review

## Troubleshooting

### Issue: Pods Not Starting

**Symptoms:**
```
kubectl get pods -n ecommerce
NAME                              READY   STATUS             RESTARTS
backend-green-xxx                 0/1     ImagePullBackOff   0
```

**Solutions:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n ecommerce

# Common causes:
# 1. Image doesn't exist
docker images | grep ecommerce-backend

# 2. Image pull policy issue
# Update deployment to use IfNotPresent for local images

# 3. Resource constraints
kubectl describe nodes
```

### Issue: Service Not Routing Traffic

**Symptoms:**
- Service selector updated but traffic not switching
- Endpoints show 0 addresses

**Solutions:**
```bash
# Check service selector
kubectl get service backend-service -n ecommerce -o yaml | grep -A 5 selector

# Check pod labels
kubectl get pods -n ecommerce --show-labels

# Verify labels match
# Service selector: app=backend, version=green
# Pod labels must include: app=backend, version=green

# Check endpoints
kubectl get endpoints backend-service -n ecommerce -o yaml
```

### Issue: Pods Ready But Not Receiving Traffic

**Symptoms:**
- Pods show READY 1/1
- Endpoints configured
- But no traffic reaching pods

**Solutions:**
```bash
# Check readiness probe
kubectl describe pod <pod-name> -n ecommerce | grep -A 10 Readiness

# Test health endpoint directly
kubectl exec -n ecommerce <pod-name> -- curl localhost:8080/actuator/health

# Check service endpoints
kubectl get endpoints backend-service -n ecommerce

# Verify network policies (if any)
kubectl get networkpolicies -n ecommerce
```

### Issue: Database Connection Failures

**Symptoms:**
```
Error: Unable to connect to database
```

**Solutions:**
```bash
# Check database is running
kubectl get pods -n ecommerce -l app=mysql

# Test connectivity from backend pod
kubectl exec -n ecommerce <backend-pod> -- nc -zv mysql-service 3306

# Check environment variables
kubectl exec -n ecommerce <backend-pod> -- env | grep DB_

# Verify secrets
kubectl get secret backend-secret -n ecommerce -o yaml
```

### Issue: High Memory Usage

**Symptoms:**
- Pods being OOMKilled
- High memory usage in `kubectl top`

**Solutions:**
```bash
# Check current usage
kubectl top pods -n ecommerce

# Increase memory limits
# Edit deployment and update:
resources:
  limits:
    memory: 1Gi  # Increase from 512Mi

# Check for memory leaks in application logs
kubectl logs -n ecommerce <pod-name> --tail=1000 | grep -i memory
```

### Issue: Rollback Not Working

**Symptoms:**
- Rollback script runs but traffic still on new version

**Solutions:**
```bash
# Manually patch services
kubectl patch service backend-service -n ecommerce \
  -p '{"spec":{"selector":{"version":"blue"}}}'

kubectl patch service frontend-service -n ecommerce \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Verify patch applied
kubectl get service backend-service -n ecommerce -o yaml | grep version

# Check if old deployment is scaled down
kubectl get deployment backend-blue -n ecommerce
# If replicas=0, scale up:
kubectl scale deployment backend-blue -n ecommerce --replicas=2
```

## Requirements Validation

This blue-green deployment implementation satisfies:

### Requirement 8.1: Simultaneous Environments ✓
Both blue and green deployments run simultaneously with separate pods and labels.

### Requirement 8.2: Atomic Traffic Switching ✓
Traffic switches atomically by updating the Kubernetes Service selector from one version to another.

### Requirement 8.3: Gradual Traffic Routing (N/A)
This is specific to canary deployments. Blue-green switches 100% of traffic at once.

### Requirement 8.4: Automatic Rollback (N/A)
This is specific to canary deployments. Blue-green provides manual rollback capability.

## Conclusion

Blue-green deployment provides a robust, zero-downtime deployment strategy with easy rollback capabilities. By maintaining two identical environments and switching traffic atomically, you can deploy new versions with confidence and minimal risk.

For questions or issues, refer to the troubleshooting section or consult the Kubernetes documentation.
