# Blue-Green Deployment Strategy

## Overview

This directory contains the implementation of a blue-green deployment strategy for the e-commerce system. Blue-green deployment allows zero-downtime deployments by maintaining two identical production environments (blue and green) and switching traffic atomically between them.

## Strategy Description

**Blue-Green Deployment** maintains two complete production environments:
- **Blue Environment**: Currently serving production traffic
- **Green Environment**: New version being deployed and tested

### Deployment Process

1. **Deploy New Version**: Deploy the new version to the inactive environment (green)
2. **Test in Isolation**: Verify the green environment works correctly without affecting production
3. **Switch Traffic**: Atomically switch the service selector to route traffic to green
4. **Monitor**: Watch for errors or issues in the new version
5. **Rollback (if needed)**: Quickly switch back to blue if problems occur
6. **Cleanup**: Once validated, the old blue environment becomes the new green for the next deployment

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Service                        │
│              (Traffic Router via Selector)                   │
│                                                               │
│  selector: version: blue  OR  selector: version: green      │
└─────────────────────────────────────────────────────────────┘
                    │                    │
        ┌───────────┘                    └───────────┐
        ▼                                            ▼
┌──────────────────┐                      ┌──────────────────┐
│  Blue Deployment │                      │ Green Deployment │
│   (version: v1)  │                      │   (version: v2)  │
│   replicas: 2    │                      │   replicas: 2    │
└──────────────────┘                      └──────────────────┘
```

## Files

- `backend-blue-deployment.yaml` - Blue version of backend deployment
- `backend-green-deployment.yaml` - Green version of backend deployment
- `backend-service-blue-green.yaml` - Service with switchable selector
- `frontend-blue-deployment.yaml` - Blue version of frontend deployment
- `frontend-green-deployment.yaml` - Green version of frontend deployment
- `frontend-service-blue-green.yaml` - Service with switchable selector
- `deploy-blue-green.sh` - Automated deployment script
- `switch-traffic.sh` - Script to switch traffic between blue and green
- `rollback.sh` - Quick rollback script

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured and connected to cluster
- Docker images built and tagged with version numbers
- Namespace `ecommerce` created

## Usage

### Initial Deployment

Deploy the blue environment (initial production):

```bash
cd k8s/blue-green
./deploy-blue-green.sh blue v1.0.0
```

### Deploy New Version

Deploy the new version to green environment:

```bash
./deploy-blue-green.sh green v2.0.0
```

### Test Green Environment

Access the green environment directly for testing:

```bash
# Port-forward to green backend
kubectl port-forward -n ecommerce deployment/backend-green 8081:8080

# Port-forward to green frontend
kubectl port-forward -n ecommerce deployment/frontend-green 8080:80

# Test the endpoints
curl http://localhost:8081/actuator/health
curl http://localhost:8080/
```

### Switch Traffic to Green

Once testing is complete, switch production traffic:

```bash
./switch-traffic.sh green
```

### Rollback to Blue

If issues are detected, quickly rollback:

```bash
./rollback.sh blue
```

Or use the switch script:

```bash
./switch-traffic.sh blue
```

### Cleanup Old Version

After the new version is stable, you can scale down or delete the old deployment:

```bash
kubectl scale deployment backend-blue -n ecommerce --replicas=0
kubectl scale deployment frontend-blue -n ecommerce --replicas=0
```

## Monitoring During Deployment

Monitor the deployment status:

```bash
# Watch pods
kubectl get pods -n ecommerce -w

# Check service endpoints
kubectl get endpoints -n ecommerce

# View logs
kubectl logs -n ecommerce -l version=green --tail=100 -f

# Check service selector
kubectl get service backend-service -n ecommerce -o yaml | grep -A 5 selector
```

## Advantages

1. **Zero Downtime**: Traffic switches atomically
2. **Easy Rollback**: Simply switch selector back to previous version
3. **Testing in Production**: Test new version with production data before switching
4. **Simple Implementation**: Uses standard Kubernetes resources

## Disadvantages

1. **Resource Usage**: Requires 2x resources during deployment
2. **Database Migrations**: Complex when schema changes are involved
3. **Stateful Services**: Database uses StatefulSet and doesn't participate in blue-green

## Best Practices

1. **Version Tags**: Always use specific version tags, never `latest`
2. **Health Checks**: Ensure readiness probes are properly configured
3. **Monitoring**: Watch metrics closely after traffic switch
4. **Gradual Rollout**: Consider testing with a small percentage first
5. **Database Compatibility**: Ensure new code works with old schema during transition
6. **Rollback Plan**: Always have a tested rollback procedure

## Troubleshooting

### Pods Not Starting

```bash
kubectl describe pod <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce
```

### Service Not Routing Traffic

```bash
# Check service selector
kubectl get service backend-service -n ecommerce -o yaml

# Check pod labels
kubectl get pods -n ecommerce --show-labels

# Verify endpoints
kubectl get endpoints backend-service -n ecommerce
```

### Traffic Not Switching

```bash
# Verify service was updated
kubectl get service backend-service -n ecommerce -o yaml | grep version

# Check if pods are ready
kubectl get pods -n ecommerce -l version=green
```

## Requirements Validation

This implementation satisfies the following requirements:

- **Requirement 8.1**: Both blue and green versions run simultaneously ✓
- **Requirement 8.2**: Traffic switches atomically by updating service selector ✓
- **Requirement 8.3**: N/A (canary-specific requirement)
- **Requirement 8.4**: N/A (canary-specific requirement)
