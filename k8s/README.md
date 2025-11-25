# Kubernetes 部署指南

本目录包含将电商系统部署到 Kubernetes 集群的清单文件。

## 前置要求

- Kubernetes 集群（minikube、kind 或云服务提供商）
- 已安装并配置 kubectl CLI 工具
- 已构建并可用的 Docker 镜像：
  - `ecommerce-frontend:latest`
  - `ecommerce-backend:latest`

## 架构

部署包含三层架构：

1. **前端层（展示层）**：Nginx 提供静态文件服务
2. **后端层（应用层）**：Spring Boot REST API
3. **数据库层（数据层）**：MySQL 持久化存储

## 目录结构

```
k8s/
├── namespace.yaml                    # 命名空间定义
├── database/
│   ├── mysql-secret.yaml            # 数据库凭证
│   ├── mysql-configmap.yaml         # 数据库配置
│   ├── mysql-initdb-configmap.yaml  # 数据库初始化脚本
│   ├── mysql-pvc.yaml               # 持久卷声明
│   ├── mysql-statefulset.yaml       # 数据库 StatefulSet
│   └── mysql-service.yaml           # 数据库服务
├── backend/
│   ├── backend-secret.yaml          # 后端凭证
│   ├── backend-configmap.yaml       # 后端配置
│   ├── backend-deployment.yaml      # 后端部署
│   └── backend-service.yaml         # 后端服务
├── frontend/
│   ├── frontend-configmap.yaml      # Nginx 配置
│   ├── frontend-deployment.yaml     # 前端部署
│   └── frontend-service.yaml        # 前端服务（LoadBalancer）
├── deploy.sh                         # 自动化部署脚本
├── cleanup.sh                        # 清理脚本
└── README.md                         # 本文件
```

## 快速开始

### 方式一：使用部署脚本（推荐）

```bash
# 使脚本可执行
chmod +x deploy.sh

# 运行部署
./deploy.sh
```

### 方式二：手动部署

```bash
# 1. 创建命名空间
kubectl apply -f namespace.yaml

# 2. 部署数据库
kubectl apply -f database/

# 3. 等待数据库就绪
kubectl wait --for=condition=ready pod -l app=mysql -n ecommerce --timeout=300s

# 4. 部署后端
kubectl apply -f backend/

# 5. 等待后端就绪
kubectl wait --for=condition=available deployment/backend -n ecommerce --timeout=300s

# 6. 部署前端
kubectl apply -f frontend/

# 7. 等待前端就绪
kubectl wait --for=condition=available deployment/frontend -n ecommerce --timeout=300s
```

## 构建 Docker 镜像

在部署之前，确保已构建 Docker 镜像：

```bash
# 构建后端镜像
cd backend
docker build -t ecommerce-backend:latest .

# 构建前端镜像
cd ../frontend
docker build -t ecommerce-frontend:latest .
```

### 针对 Minikube

如果使用 minikube，将镜像加载到 minikube 的 Docker 守护进程：

```bash
# 使用 minikube 的 Docker 守护进程
eval $(minikube docker-env)

# 构建镜像
cd backend && docker build -t ecommerce-backend:latest .
cd ../frontend && docker build -t ecommerce-frontend:latest .
```

### 针对 Kind

如果使用 kind，将镜像加载到 kind 集群：

```bash
# 先构建镜像
docker build -t ecommerce-backend:latest ./backend
docker build -t ecommerce-frontend:latest ./frontend

# 加载到 kind
kind load docker-image ecommerce-backend:latest
kind load docker-image ecommerce-frontend:latest
```

## 访问应用

### Minikube

```bash
# 获取服务 URL
minikube service frontend-service -n ecommerce

# 或使用端口转发
kubectl port-forward -n ecommerce service/frontend-service 8080:80
# 访问 http://localhost:8080
```

### Kind 或其他本地集群

```bash
# 使用端口转发
kubectl port-forward -n ecommerce service/frontend-service 8080:80
# 访问 http://localhost:8080
```

### 云服务提供商（支持 LoadBalancer）

```bash
# 获取外部 IP
kubectl get service frontend-service -n ecommerce

# 等待 EXTERNAL-IP 分配
# 访问 http://<EXTERNAL-IP>
```

## 验证部署

### 检查所有资源

```bash
kubectl get all -n ecommerce
```

### 检查 Pod 状态

```bash
kubectl get pods -n ecommerce
```

### 检查服务

```bash
kubectl get services -n ecommerce
```

### 检查持久卷

```bash
kubectl get pvc -n ecommerce
```

### 查看日志

```bash
# 前端日志
kubectl logs -n ecommerce -l app=frontend

# 后端日志
kubectl logs -n ecommerce -l app=backend

# 数据库日志
kubectl logs -n ecommerce -l app=mysql
```

## 健康检查

所有组件都配置了健康检查：

### 数据库
- **存活探针**：每 10 秒执行 `mysqladmin ping`
- **就绪探针**：每 10 秒执行 `mysqladmin ping`

### 后端
- **存活探针**：每 30 秒 HTTP GET `/actuator/health`
- **就绪探针**：每 10 秒 HTTP GET `/actuator/health`

### 前端
- **存活探针**：每 30 秒 HTTP GET `/health`
- **就绪探针**：每 10 秒 HTTP GET `/health`

## 扩缩容

### 扩展前端

```bash
kubectl scale deployment frontend -n ecommerce --replicas=3
```

### 扩展后端

```bash
kubectl scale deployment backend -n ecommerce --replicas=3
```

注意：数据库使用 StatefulSet，副本数为 1（此设置不支持水平扩展）。

## 配置

### Secret（密钥）

敏感数据存储在 Kubernetes Secret 中：

- `mysql-secret`：数据库凭证
- `backend-secret`：后端数据库凭证

更新 Secret：

```bash
# 编辑 Secret
kubectl edit secret mysql-secret -n ecommerce

# 或删除并重新创建
kubectl delete secret mysql-secret -n ecommerce
kubectl apply -f database/mysql-secret.yaml
```

### ConfigMap（配置映射）

配置数据存储在 ConfigMap 中：

- `mysql-config`：数据库配置
- `mysql-initdb-config`：数据库初始化脚本
- `backend-config`：后端环境变量
- `frontend-config`：Nginx 配置

更新 ConfigMap：

```bash
# 编辑 ConfigMap
kubectl edit configmap backend-config -n ecommerce

# 或删除并重新创建
kubectl delete configmap backend-config -n ecommerce
kubectl apply -f backend/backend-configmap.yaml

# 重启 Pod 以应用更改
kubectl rollout restart deployment backend -n ecommerce
```

## 资源限制

### 前端
- 请求：250m CPU，128Mi 内存
- 限制：500m CPU，256Mi 内存

### 后端
- 请求：500m CPU，256Mi 内存
- 限制：1000m CPU，512Mi 内存

### 数据库
- 请求：500m CPU，512Mi 内存
- 限制：1000m CPU，1Gi 内存

## 持久化存储

数据库使用 PersistentVolumeClaim (PVC) 进行数据持久化：

- **名称**：`mysql-pvc`
- **大小**：5Gi
- **访问模式**：ReadWriteOnce
- **存储类**：standard（默认）

检查 PVC 状态：

```bash
kubectl get pvc -n ecommerce
```

## 故障排查

### Pod 无法启动

```bash
# 检查 Pod 状态
kubectl get pods -n ecommerce

# 查看 Pod 事件
kubectl describe pod <pod-name> -n ecommerce

# 查看日志
kubectl logs <pod-name> -n ecommerce
```

### 数据库连接问题

```bash
# 检查数据库是否就绪
kubectl get pods -n ecommerce -l app=mysql

# 查看数据库日志
kubectl logs -n ecommerce -l app=mysql

# 从后端 Pod 测试数据库连接
kubectl exec -it -n ecommerce <backend-pod-name> -- sh
# 在 Pod 内：nc -zv mysql-service 3306
```

### 镜像拉取错误

如果使用 minikube 或 kind 的本地镜像：

```bash
# 针对 minikube
eval $(minikube docker-env)
# 重新构建镜像

# 针对 kind
kind load docker-image ecommerce-backend:latest
kind load docker-image ecommerce-frontend:latest
```

### 服务无法访问

```bash
# 检查服务
kubectl get service frontend-service -n ecommerce

# 使用端口转发作为备选方案
kubectl port-forward -n ecommerce service/frontend-service 8080:80
```

### 持久卷问题

```bash
# 检查 PVC 状态
kubectl get pvc -n ecommerce

# 检查 PV
kubectl get pv

# 查看 PVC 事件
kubectl describe pvc mysql-pvc -n ecommerce
```

## 清理

### 使用清理脚本

```bash
# 使脚本可执行
chmod +x cleanup.sh

# 运行清理
./cleanup.sh
```

### 手动清理

```bash
# 删除命名空间中的所有资源
kubectl delete namespace ecommerce

# 或单独删除资源
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f database/
kubectl delete -f namespace.yaml
```

注意：删除命名空间将同时删除其中的所有资源，包括 PVC 和数据。

## 生产环境注意事项

对于生产部署，请考虑：

1. **安全性**：
   - 在 Secret 中使用更强的密码
   - 为服务启用 TLS/SSL
   - 使用网络策略限制流量
   - 以非 root 用户运行容器
   - 使用 Pod 安全策略/标准

2. **高可用性**：
   - 跨多个可用区部署
   - 使用数据库复制（MySQL 主从）
   - 实施适当的备份策略
   - 使用水平 Pod 自动扩缩容（HPA）

3. **监控**：
   - 部署 Prometheus 和 Grafana
   - 配置告警规则
   - 使用集中式日志（ELK 栈）
   - 实施分布式追踪

4. **存储**：
   - 使用云服务提供商的存储类
   - 实施备份和恢复程序
   - 考虑使用托管数据库服务

5. **Ingress**：
   - 使用 Ingress 控制器而非 LoadBalancer
   - 配置 TLS 证书
   - 实施速率限制
   - 添加身份验证/授权

## 测试部署

### 测试数据库连接

```bash
# 进入后端 Pod 的 shell
kubectl exec -it -n ecommerce deployment/backend -- sh

# 测试数据库连接
nc -zv mysql-service 3306
```

### 测试 API 端点

```bash
# 端口转发后端服务
kubectl port-forward -n ecommerce service/backend-service 8080:8080

# 测试 API
curl http://localhost:8080/api/products
```

### 测试前端

```bash
# 端口转发前端服务
kubectl port-forward -n ecommerce service/frontend-service 8080:80

# 在浏览器中访问
open http://localhost:8080
```

## 其他资源

- [Kubernetes 文档](https://kubernetes.io/zh-cn/docs/)
- [kubectl 速查表](https://kubernetes.io/zh-cn/docs/reference/kubectl/cheatsheet/)
- [Minikube 文档](https://minikube.sigs.k8s.io/docs/)
- [Kind 文档](https://kind.sigs.k8s.io/)
