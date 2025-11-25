# Kubernetes 部署指南

本文档提供了将电商系统部署到 Kubernetes 集群的完整指南。

## 目录
1. [概述](#概述)
2. [前置要求](#前置要求)
3. [架构设计](#架构设计)
4. [部署步骤](#部署步骤)
5. [配置管理](#配置管理)
6. [服务暴露](#服务暴露)
7. [扩缩容](#扩缩容)
8. [监控和日志](#监控和日志)
9. [故障排查](#故障排查)

## 概述

Kubernetes 部署将电商系统的三个服务(前端、后端、数据库)部署为 Kubernetes 工作负载,利用 Kubernetes 的编排、扩展和自我修复功能。

### 部署特性

- **高可用性**: 多副本部署
- **自动恢复**: Pod 故障自动重启
- **弹性扩展**: 基于负载自动扩缩容
- **滚动更新**: 零停机部署
- **配置管理**: ConfigMap 和 Secret
- **持久化存储**: StatefulSet 和 PVC

## 前置要求

### Kubernetes 集群

需要运行中的 Kubernetes 集群:

**本地开发**:
- Minikube 1.30+
- Kind 0.20+
- Docker Desktop Kubernetes

**云服务**:
- Google Kubernetes Engine (GKE)
- Amazon Elastic Kubernetes Service (EKS)
- Azure Kubernetes Service (AKS)

### 工具安装

```bash
# 安装 kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 验证安装
kubectl version --client

# 安装 Minikube (可选)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 安装 Kind (可选)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### 验证集群

```bash
# 检查集群连接
kubectl cluster-info

# 查看节点
kubectl get nodes

# 检查资源
kubectl top nodes
```

## 架构设计

### Kubernetes 资源层次

```
Namespace: ecommerce
│
├── Database Layer
│   ├── StatefulSet: mysql (1 replica)
│   ├── Service: mysql-service (ClusterIP, Headless)
│   ├── PVC: mysql-pvc (5Gi)
│   ├── Secret: mysql-secret
│   └── ConfigMap: mysql-config, mysql-initdb-config
│
├── Application Layer
│   ├── Deployment: backend (2 replicas)
│   ├── Service: backend-service (ClusterIP)
│   ├── Secret: backend-secret
│   └── ConfigMap: backend-config
│
└── Presentation Layer
    ├── Deployment: frontend (2 replicas)
    ├── Service: frontend-service (LoadBalancer)
    └── ConfigMap: frontend-config
```

### 网络架构

```
External Traffic
      ↓
LoadBalancer (frontend-service)
      ↓
Frontend Pods (Nginx) - 2 replicas
      ↓
ClusterIP (backend-service)
      ↓
Backend Pods (Spring Boot) - 2 replicas
      ↓
ClusterIP (mysql-service - Headless)
      ↓
MySQL StatefulSet - 1 replica
      ↓
PersistentVolume (5Gi)
```

## 部署步骤

### 方法一: 自动化部署(推荐)

```bash
# 进入 k8s 目录
cd k8s

# 运行部署脚本
chmod +x deploy.sh
./deploy.sh
```

脚本将自动:
1. 创建命名空间
2. 部署数据库并等待就绪
3. 部署后端并等待就绪
4. 部署前端并等待就绪
5. 显示部署状态

### 方法二: 手动部署

#### 步骤 1: 创建命名空间

```bash
kubectl apply -f namespace.yaml
```

验证:
```bash
kubectl get namespace ecommerce
```

#### 步骤 2: 部署数据库

```bash
# 应用 Secret
kubectl apply -f database/mysql-secret.yaml

# 应用 ConfigMap
kubectl apply -f database/mysql-configmap.yaml
kubectl apply -f database/mysql-initdb-configmap.yaml

# 创建 PVC
kubectl apply -f database/mysql-pvc.yaml

# 验证 PVC 已绑定
kubectl get pvc -n ecommerce

# 部署 StatefulSet
kubectl apply -f database/mysql-statefulset.yaml

# 创建 Service
kubectl apply -f database/mysql-service.yaml

# 等待数据库就绪
kubectl wait --for=condition=ready pod -l app=mysql -n ecommerce --timeout=300s
```

验证:
```bash
kubectl get pods -n ecommerce -l app=mysql
kubectl logs -n ecommerce -l app=mysql
```

#### 步骤 3: 部署后端

```bash
# 应用 Secret
kubectl apply -f backend/backend-secret.yaml

# 应用 ConfigMap
kubectl apply -f backend/backend-configmap.yaml

# 部署 Deployment
kubectl apply -f backend/backend-deployment.yaml

# 创建 Service
kubectl apply -f backend/backend-service.yaml

# 等待后端就绪
kubectl wait --for=condition=available deployment/backend -n ecommerce --timeout=300s
```

验证:
```bash
kubectl get pods -n ecommerce -l app=backend
kubectl logs -n ecommerce -l app=backend
```

#### 步骤 4: 部署前端

```bash
# 应用 ConfigMap
kubectl apply -f frontend/frontend-configmap.yaml

# 部署 Deployment
kubectl apply -f frontend/frontend-deployment.yaml

# 创建 Service
kubectl apply -f frontend/frontend-service.yaml

# 等待前端就绪
kubectl wait --for=condition=available deployment/frontend -n ecommerce --timeout=300s
```

验证:
```bash
kubectl get pods -n ecommerce -l app=frontend
kubectl logs -n ecommerce -l app=frontend
```

### 构建和加载镜像

#### 针对 Minikube

```bash
# 使用 Minikube Docker 守护进程
eval $(minikube docker-env)

# 构建镜像
docker build -t ecommerce-backend:latest ./backend
docker build -t ecommerce-frontend:latest ./frontend

# 镜像现在在 Minikube 中可用
```

#### 针对 Kind

```bash
# 先构建镜像
docker build -t ecommerce-backend:latest ./backend
docker build -t ecommerce-frontend:latest ./frontend

# 加载到 Kind 集群
kind load docker-image ecommerce-backend:latest
kind load docker-image ecommerce-frontend:latest
```

#### 针对云集群

```bash
# 标记镜像
docker tag ecommerce-backend:latest your-registry/ecommerce-backend:latest
docker tag ecommerce-frontend:latest your-registry/ecommerce-frontend:latest

# 推送到仓库
docker push your-registry/ecommerce-backend:latest
docker push your-registry/ecommerce-frontend:latest

# 更新 Kubernetes 清单中的镜像引用
```

## 配置管理

### Secret 管理

**查看 Secret**:
```bash
kubectl get secrets -n ecommerce
```

**更新 Secret**:
```bash
# 方法 1: 使用 kubectl edit
kubectl edit secret mysql-secret -n ecommerce

# 方法 2: 删除并重新创建
kubectl delete secret mysql-secret -n ecommerce
kubectl apply -f database/mysql-secret.yaml

# 方法 3: 使用 kubectl create
kubectl create secret generic mysql-secret \
  --from-literal=mysql-root-password=newpassword \
  --from-literal=mysql-password=newpassword \
  -n ecommerce \
  --dry-run=client -o yaml | kubectl apply -f -
```

**重启 Pod 以应用新 Secret**:
```bash
kubectl rollout restart statefulset mysql -n ecommerce
kubectl rollout restart deployment backend -n ecommerce
```

### ConfigMap 管理

**查看 ConfigMap**:
```bash
kubectl get configmap -n ecommerce
kubectl describe configmap backend-config -n ecommerce
```

**更新 ConfigMap**:
```bash
# 方法 1: 编辑现有
kubectl edit configmap backend-config -n ecommerce

# 方法 2: 从文件更新
kubectl create configmap backend-config \
  --from-file=config.properties \
  -n ecommerce \
  --dry-run=client -o yaml | kubectl apply -f -

# 重启 Deployment
kubectl rollout restart deployment backend -n ecommerce
```

### 环境变量

**在 Deployment 中设置**:
```yaml
env:
  - name: DB_HOST
    value: mysql-service
  - name: DB_PORT
    value: "3306"
  - name: DB_NAME
    valueFrom:
      configMapKeyRef:
        name: backend-config
        key: database-name
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: backend-secret
        key: mysql-password
```

## 服务暴露

### 访问方法

#### 方法 1: LoadBalancer (云环境)

```bash
# 查看外部 IP
kubectl get service frontend-service -n ecommerce

# 访问应用
# http://<EXTERNAL-IP>
```

#### 方法 2: NodePort (本地集群)

修改 `frontend-service.yaml`:
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

访问:
```bash
# Minikube
minikube service frontend-service -n ecommerce

# 或使用 NodePort
http://<node-ip>:30080
```

#### 方法 3: Port Forward (开发)

```bash
# 转发前端
kubectl port-forward -n ecommerce service/frontend-service 8080:80

# 转发后端
kubectl port-forward -n ecommerce service/backend-service 8081:8080

# 访问
http://localhost:8080  # 前端
http://localhost:8081/api/products  # 后端
```

#### 方法 4: Ingress (生产推荐)

**安装 Ingress 控制器**:
```bash
# Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

**创建 Ingress 资源**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: ecommerce.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
  tls:
  - hosts:
    - ecommerce.example.com
    secretName: ecommerce-tls
```

## 扩缩容

### 手动扩缩容

```bash
# 扩展前端
kubectl scale deployment frontend -n ecommerce --replicas=5

# 扩展后端
kubectl scale deployment backend -n ecommerce --replicas=3

# 查看状态
kubectl get pods -n ecommerce
```

### 水平 Pod 自动扩缩(HPA)

**前置要求**:安装 Metrics Server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**创建 HPA**:
```bash
# 基于 CPU 的自动扩缩
kubectl autoscale deployment frontend \
  -n ecommerce \
  --cpu-percent=70 \
  --min=2 \
  --max=10

kubectl autoscale deployment backend \
  -n ecommerce \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

**HPA YAML 配置**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: ecommerce
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**查看 HPA 状态**:
```bash
kubectl get hpa -n ecommerce
kubectl describe hpa backend-hpa -n ecommerce
```

### 垂直 Pod 自动扩缩(VPA)

**安装 VPA**:
```bash
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

**创建 VPA**:
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: backend-vpa
  namespace: ecommerce
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  updatePolicy:
    updateMode: "Auto"
```

## 监控和日志

### 查看资源

```bash
# 查看所有资源
kubectl get all -n ecommerce

# 查看 Pods
kubectl get pods -n ecommerce -o wide

# 查看 Services
kubectl get svc -n ecommerce

# 查看 Deployments
kubectl get deployments -n ecommerce

# 查看 StatefulSets
kubectl get statefulsets -n ecommerce

# 查看 PVC
kubectl get pvc -n ecommerce
```

### 查看日志

```bash
# 查看特定 Pod 日志
kubectl logs <pod-name> -n ecommerce

# 实时跟踪日志
kubectl logs -f <pod-name> -n ecommerce

# 查看所有前端 Pod 日志
kubectl logs -l app=frontend -n ecommerce

# 查看所有后端 Pod 日志
kubectl logs -l app=backend -n ecommerce

# 查看数据库日志
kubectl logs -l app=mysql -n ecommerce

# 查看之前容器的日志
kubectl logs <pod-name> --previous -n ecommerce
```

### 事件监控

```bash
# 查看命名空间事件
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# 持续监控事件
kubectl get events -n ecommerce --watch

# 查看 Pod 事件
kubectl describe pod <pod-name> -n ecommerce
```

### 资源使用

```bash
# 查看 Pod 资源使用
kubectl top pods -n ecommerce

# 查看节点资源使用
kubectl top nodes

# 查看特定 Pod 详细信息
kubectl describe pod <pod-name> -n ecommerce
```

### 部署 Prometheus 和 Grafana

**使用 Helm**:
```bash
# 安装 Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 添加 Prometheus 仓库
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安装 Prometheus Stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# 访问 Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000
# 默认: admin/prom-operator
```

## 故障排查

### Pod 无法启动

**检查 Pod 状态**:
```bash
kubectl get pods -n ecommerce
kubectl describe pod <pod-name> -n ecommerce
```

**常见问题**:

1. **ImagePullBackOff**:
```bash
# 检查镜像是否存在
docker images | grep ecommerce

# Minikube: 使用正确的 Docker 守护进程
eval $(minikube docker-env)

# Kind: 加载镜像
kind load docker-image ecommerce-backend:latest
```

2. **CrashLoopBackOff**:
```bash
# 查看日志
kubectl logs <pod-name> -n ecommerce

# 检查之前容器的日志
kubectl logs <pod-name> --previous -n ecommerce

# 进入容器调试
kubectl exec -it <pod-name> -n ecommerce -- /bin/sh
```

3. **Pending 状态**:
```bash
# 检查资源限制
kubectl describe pod <pod-name> -n ecommerce

# 查看节点资源
kubectl top nodes

# 检查 PVC 绑定
kubectl get pvc -n ecommerce
```

### 服务连接问题

**测试服务连接**:
```bash
# 从后端 Pod 测试数据库连接
BACKEND_POD=$(kubectl get pods -n ecommerce -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n ecommerce $BACKEND_POD -- nc -zv mysql-service 3306

# 从前端 Pod 测试后端连接
FRONTEND_POD=$(kubectl get pods -n ecommerce -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n ecommerce $FRONTEND_POD -- wget -O- http://backend-service:8080/actuator/health
```

**检查服务和端点**:
```bash
# 查看服务
kubectl get svc -n ecommerce

# 查看端点
kubectl get endpoints -n ecommerce

# 描述服务
kubectl describe svc backend-service -n ecommerce
```

### 健康检查失败

**查看探针配置**:
```bash
kubectl describe pod <pod-name> -n ecommerce | grep -A 10 Liveness
kubectl describe pod <pod-name> -n ecommerce | grep -A 10 Readiness
```

**手动测试端点**:
```bash
# 测试后端健康端点
kubectl exec -it <backend-pod> -n ecommerce -- wget -O- http://localhost:8080/actuator/health

# 测试前端健康端点
kubectl exec -it <frontend-pod> -n ecommerce -- wget -O- http://localhost:80/health
```

### 存储问题

**检查 PVC 状态**:
```bash
# 查看 PVC
kubectl get pvc -n ecommerce

# 描述 PVC
kubectl describe pvc mysql-pvc -n ecommerce

# 查看 PV
kubectl get pv
```

**PVC 未绑定**:
```bash
# 检查 StorageClass
kubectl get storageclass

# 查看 PVC 事件
kubectl describe pvc mysql-pvc -n ecommerce

# 手动创建 PV (如果需要)
```

### 配置问题

**检查 ConfigMap 和 Secret**:
```bash
# 查看 ConfigMap
kubectl get configmap -n ecommerce
kubectl describe configmap backend-config -n ecommerce

# 查看 Secret
kubectl get secret -n ecommerce
kubectl describe secret mysql-secret -n ecommerce

# 查看 Secret 值(base64 解码)
kubectl get secret mysql-secret -n ecommerce -o jsonpath='{.data.mysql-password}' | base64 -d
```

## 更新和回滚

### 滚动更新

```bash
# 更新镜像
kubectl set image deployment/backend backend=ecommerce-backend:v2 -n ecommerce

# 查看更新状态
kubectl rollout status deployment/backend -n ecommerce

# 暂停更新
kubectl rollout pause deployment/backend -n ecommerce

# 恢复更新
kubectl rollout resume deployment/backend -n ecommerce
```

### 回滚

```bash
# 查看历史
kubectl rollout history deployment/backend -n ecommerce

# 回滚到上一个版本
kubectl rollout undo deployment/backend -n ecommerce

# 回滚到特定版本
kubectl rollout undo deployment/backend --to-revision=2 -n ecommerce
```

## 清理

### 删除应用

```bash
# 使用清理脚本
cd k8s
chmod +x cleanup.sh
./cleanup.sh

# 或手动删除
kubectl delete namespace ecommerce
```

### 删除特定资源

```bash
# 删除 Deployment
kubectl delete deployment frontend -n ecommerce

# 删除 Service
kubectl delete service frontend-service -n ecommerce

# 删除 ConfigMap
kubectl delete configmap frontend-config -n ecommerce
```

## 生产最佳实践

### 1. 资源限制

始终设置资源请求和限制:
```yaml
resources:
  requests:
    cpu: 500m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

### 2. 健康检查

配置存活和就绪探针:
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

### 3. 副本数

生产环境至少运行 2 个副本:
```yaml
replicas: 2
```

### 4. Pod 反亲和性

跨节点分布 Pod:
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - backend
        topologyKey: kubernetes.io/hostname
```

### 5. 网络策略

限制 Pod 间通信:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: ecommerce
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: mysql
    ports:
    - protocol: TCP
      port: 3306
```

### 6. 备份策略

定期备份数据库:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: ecommerce
spec:
  schedule: "0 2 * * *"  # 每天凌晨 2 点
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            command:
            - /bin/sh
            - -c
            - mysqldump -h mysql-service -u root -p$MYSQL_ROOT_PASSWORD ecommerce > /backup/backup-$(date +%Y%m%d).sql
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: mysql-root-password
            volumeMounts:
            - name: backup
              mountPath: /backup
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

## 其他资源

- [Kubernetes 官方文档](https://kubernetes.io/zh-cn/docs/)
- [kubectl 速查表](https://kubernetes.io/zh-cn/docs/reference/kubectl/cheatsheet/)
- [快速入门指南](../k8s/QUICK_START.md)
- [部署检查清单](../k8s/DEPLOYMENT_CHECKLIST.md)
- [故障排查指南](troubleshooting.md)
