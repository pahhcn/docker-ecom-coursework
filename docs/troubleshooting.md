# 故障排查指南

## 目录
1. [概述](#概述)
2. [Docker Compose 问题](#docker-compose-问题)
3. [Kubernetes 问题](#kubernetes-问题)
4. [应用程序问题](#应用程序问题)
5. [网络问题](#网络问题)
6. [存储问题](#存储问题)
7. [性能问题](#性能问题)
8. [安全问题](#安全问题)

## 概述

本指南提供了常见问题的诊断步骤和解决方案,涵盖 Docker Compose 和 Kubernetes 部署。

### 通用调试工具

```bash
# Docker 命令
docker ps                    # 查看运行中的容器
docker logs <container>      # 查看容器日志
docker inspect <container>   # 查看容器详细信息
docker exec -it <container> sh  # 进入容器

# Kubernetes 命令
kubectl get pods            # 查看 Pods
kubectl logs <pod>          # 查看 Pod 日志
kubectl describe <resource> # 查看资源详细信息
kubectl exec -it <pod> -- sh  # 进入 Pod
```

## Docker Compose 问题

### 问题 1: 容器无法启动

**症状**:
```bash
$ docker compose up
ERROR: for backend  Container "xxx" exited with code 1
```

**诊断步骤**:
```bash
# 查看日志
docker compose logs backend

# 查看退出代码
docker compose ps

# 详细输出
docker compose up --no-start
docker compose logs
```

**常见原因和解决方案**:

**1. 端口已被占用**
```bash
# 查找占用端口的进程
sudo lsof -i :8080
sudo lsof -i :3306

# 停止进程或修改端口
# 编辑 docker-compose.yml
ports:
  - "8081:8080"  # 更改主机端口
```

**2. 环境变量缺失**
```bash
# 检查环境变量
docker compose config

# 创建 .env 文件
cp .env.example .env
nano .env
```

**3. 依赖服务未就绪**
```yaml
# 添加健康检查和依赖
depends_on:
  mysql:
    condition: service_healthy
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### 问题 2: 数据库连接失败

**症状**:
```
backend    | Could not connect to MySQL server
backend    | Connection refused
```

**诊断步骤**:
```bash
# 检查数据库容器状态
docker compose ps mysql

# 查看数据库日志
docker compose logs mysql

# 测试网络连接
docker compose exec backend nc -zv mysql 3306

# 检查环境变量
docker compose exec backend env | grep DB_
```

**解决方案**:

**1. 数据库未就绪**
```bash
# 等待数据库启动
docker compose up -d mysql
docker compose logs -f mysql
# 等待 "ready for connections" 消息

# 重启后端
docker compose restart backend
```

**2. 网络配置问题**
```yaml
# 确保使用相同网络
networks:
  ecommerce-network:
    driver: bridge

services:
  backend:
    networks:
      - ecommerce-network
  mysql:
    networks:
      - ecommerce-network
```

**3. 主机名解析失败**
```bash
# 测试 DNS 解析
docker compose exec backend nslookup mysql

# 使用服务名称而非 localhost
DB_HOST=mysql  # 不是 localhost
```

### 问题 3: 卷权限问题

**症状**:
```
mysql      | chown: changing ownership of '/var/lib/mysql': Operation not permitted
```

**诊断步骤**:
```bash
# 检查卷
docker volume ls
docker volume inspect dockerwork_mysql-data

# 检查权限
docker compose exec mysql ls -la /var/lib/mysql
```

**解决方案**:

**1. Linux 上的权限问题**
```bash
# 删除并重新创建卷
docker compose down -v
docker compose up -d

# 或手动修复权限
docker run --rm -v dockerwork_mysql-data:/data alpine chmod -R 777 /data
```

**2. SELinux 问题**
```bash
# 临时禁用 SELinux
sudo setenforce 0

# 或添加 SELinux 标签
volumes:
  - mysql-data:/var/lib/mysql:z
```

### 问题 4: 镜像构建失败

**症状**:
```
ERROR: failed to solve: process "/bin/sh -c mvn clean package" did not complete successfully
```

**诊断步骤**:
```bash
# 清理构建缓存
docker builder prune -a

# 使用 --no-cache 构建
docker compose build --no-cache

# 详细输出
docker compose build --progress=plain
```

**解决方案**:

**1. Maven 依赖下载失败**
```dockerfile
# 添加重试逻辑
RUN mvn clean package -DskipTests || \
    mvn clean package -DskipTests || \
    mvn clean package -DskipTests
```

**2. 内存不足**
```bash
# 增加 Docker 内存限制
# Docker Desktop: Settings → Resources → Memory

# 或在构建时限制资源
docker compose build --memory 4g
```

**3. 网络问题**
```bash
# 使用代理
docker build --build-arg HTTP_PROXY=http://proxy:port .

# 或使用镜像源
# 在 pom.xml 中配置 Maven 镜像
```

### 问题 5: 容器频繁重启

**症状**:
```bash
$ docker compose ps
NAME      STATUS
backend   Restarting (1) 5 seconds ago
```

**诊断步骤**:
```bash
# 查看重启次数
docker compose ps

# 查看日志
docker compose logs --tail=100 backend

# 检查退出代码
docker inspect backend --format='{{.State.ExitCode}}'
```

**解决方案**:

**1. 应用程序崩溃**
```bash
# 查看完整日志
docker compose logs backend

# 检查 Java 堆内存
# 添加 JVM 参数
environment:
  JAVA_OPTS: "-Xms256m -Xmx512m"
```

**2. 健康检查失败**
```yaml
# 调整健康检查参数
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 60s  # 增加启动时间
```

## Kubernetes 问题

### 问题 1: Pod 处于 Pending 状态

**症状**:
```bash
$ kubectl get pods -n ecommerce
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx                 0/1     Pending   0          5m
```

**诊断步骤**:
```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n ecommerce

# 检查事件
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# 查看节点资源
kubectl top nodes
kubectl describe nodes
```

**常见原因和解决方案**:

**1. 资源不足**
```bash
# 减少资源请求
# 编辑 deployment.yaml
resources:
  requests:
    cpu: 250m     # 从 500m 减少
    memory: 128Mi # 从 256Mi 减少
```

**2. PVC 未绑定**
```bash
# 检查 PVC 状态
kubectl get pvc -n ecommerce

# 检查 StorageClass
kubectl get storageclass

# 手动创建 PV (如果需要)
```

**3. 节点选择器不匹配**
```bash
# 检查节点标签
kubectl get nodes --show-labels

# 移除节点选择器或添加标签
kubectl label nodes <node-name> <label-key>=<label-value>
```

### 问题 2: Pod 处于 CrashLoopBackOff 状态

**症状**:
```bash
$ kubectl get pods -n ecommerce
NAME                        READY   STATUS             RESTARTS   AGE
backend-xxx                 0/1     CrashLoopBackOff   5          3m
```

**诊断步骤**:
```bash
# 查看当前日志
kubectl logs <pod-name> -n ecommerce

# 查看之前容器的日志
kubectl logs <pod-name> --previous -n ecommerce

# 查看 Pod 事件
kubectl describe pod <pod-name> -n ecommerce

# 进入容器调试 (如果可能)
kubectl exec -it <pod-name> -n ecommerce -- sh
```

**解决方案**:

**1. 应用程序错误**
```bash
# 检查日志中的错误
kubectl logs <pod-name> -n ecommerce | grep -i error

# 检查配置
kubectl get configmap backend-config -n ecommerce -o yaml
kubectl get secret backend-secret -n ecommerce -o yaml
```

**2. 数据库连接失败**
```bash
# 测试数据库连接
kubectl exec -it <backend-pod> -n ecommerce -- nc -zv mysql-service 3306

# 检查 Service
kubectl get svc mysql-service -n ecommerce
kubectl get endpoints mysql-service -n ecommerce
```

**3. 健康检查过于严格**
```yaml
# 增加初始延迟和超时
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 90  # 增加
  timeoutSeconds: 5
  periodSeconds: 30
  failureThreshold: 5      # 增加
```

### 问题 3: ImagePullBackOff 错误

**症状**:
```bash
$ kubectl get pods -n ecommerce
NAME                        READY   STATUS             RESTARTS   AGE
backend-xxx                 0/1     ImagePullBackOff   0          2m
```

**诊断步骤**:
```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n ecommerce

# 检查事件
kubectl get events -n ecommerce | grep <pod-name>
```

**解决方案**:

**1. Minikube - 镜像未加载**
```bash
# 使用 Minikube Docker 守护进程
eval $(minikube docker-env)

# 重新构建镜像
docker build -t ecommerce-backend:latest ./backend

# 验证镜像存在
docker images | grep ecommerce
```

**2. Kind - 镜像未加载**
```bash
# 加载镜像到 Kind
kind load docker-image ecommerce-backend:latest
kind load docker-image ecommerce-frontend:latest

# 验证
docker exec -it kind-control-plane crictl images | grep ecommerce
```

**3. 镜像拉取策略问题**
```yaml
# 使用本地镜像
spec:
  containers:
  - name: backend
    image: ecommerce-backend:latest
    imagePullPolicy: IfNotPresent  # 或 Never
```

**4. 私有仓库认证**
```bash
# 创建 Docker 仓库 Secret
kubectl create secret docker-registry regcred \
  --docker-server=<your-registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n ecommerce

# 在 Deployment 中使用
spec:
  imagePullSecrets:
  - name: regcred
```

### 问题 4: Service 无法访问

**症状**:
```bash
# 无法访问服务
$ curl http://<service-ip>:8080
curl: (7) Failed to connect
```

**诊断步骤**:
```bash
# 检查 Service
kubectl get svc -n ecommerce
kubectl describe svc backend-service -n ecommerce

# 检查 Endpoints
kubectl get endpoints backend-service -n ecommerce

# 检查 Pod 标签
kubectl get pods -n ecommerce --show-labels

# 测试 Pod 直接访问
kubectl port-forward <pod-name> 8080:8080 -n ecommerce
curl http://localhost:8080/api/products
```

**解决方案**:

**1. 标签选择器不匹配**
```yaml
# 确保 Service 选择器匹配 Pod 标签
# Service
spec:
  selector:
    app: backend

# Deployment
spec:
  template:
    metadata:
      labels:
        app: backend
```

**2. 端口配置错误**
```yaml
# 检查端口配置
spec:
  ports:
  - port: 8080        # Service 端口
    targetPort: 8080  # Pod 端口
    protocol: TCP
```

**3. 网络策略阻止**
```bash
# 检查网络策略
kubectl get networkpolicy -n ecommerce

# 临时删除以测试
kubectl delete networkpolicy <policy-name> -n ecommerce
```

### 问题 5: PVC 绑定失败

**症状**:
```bash
$ kubectl get pvc -n ecommerce
NAME         STATUS    VOLUME   CAPACITY   ACCESS MODES
mysql-pvc    Pending                                    
```

**诊断步骤**:
```bash
# 查看 PVC 详情
kubectl describe pvc mysql-pvc -n ecommerce

# 检查 StorageClass
kubectl get storageclass

# 查看 PV
kubectl get pv
```

**解决方案**:

**1. 没有可用的 PV**
```bash
# 创建本地 PV (仅用于测试)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /tmp/mysql-data
EOF
```

**2. StorageClass 不存在**
```bash
# Minikube: 启用 storage provisioner
minikube addons enable storage-provisioner
minikube addons enable default-storageclass

# 验证
kubectl get storageclass
```

**3. 访问模式不匹配**
```yaml
# 检查并匹配访问模式
# PVC
spec:
  accessModes:
    - ReadWriteOnce

# PV
spec:
  accessModes:
    - ReadWriteOnce
```

## 应用程序问题

### 问题 1: 后端 API 返回 500 错误

**症状**:
```bash
$ curl http://localhost:8080/api/products
{"timestamp":"...","status":500,"error":"Internal Server Error"}
```

**诊断步骤**:
```bash
# 查看后端日志
docker compose logs backend
# 或
kubectl logs -l app=backend -n ecommerce

# 检查数据库连接
docker compose exec backend nc -zv mysql 3306

# 查看环境变量
docker compose exec backend env | grep DB_
```

**解决方案**:

**1. 数据库连接失败**
```bash
# 验证数据库运行
docker compose ps mysql
kubectl get pods -l app=mysql -n ecommerce

# 检查凭证
# 确保环境变量正确
```

**2. 数据库未初始化**
```bash
# 重新初始化数据库
docker compose down -v
docker compose up -d mysql
# 等待初始化完成
docker compose up -d backend
```

### 问题 2: 前端显示空白页面

**症状**:
- 浏览器显示空白页面
- 控制台显示 CORS 错误或 API 请求失败

**诊断步骤**:
```bash
# 检查前端日志
docker compose logs frontend
kubectl logs -l app=frontend -n ecommerce

# 检查浏览器控制台
# F12 → Console

# 测试静态文件
curl http://localhost:80

# 测试 API 代理
curl http://localhost:80/api/products
```

**解决方案**:

**1. Nginx 配置错误**
```bash
# 验证 nginx 配置
docker compose exec frontend nginx -t

# 查看配置
docker compose exec frontend cat /etc/nginx/nginx.conf
```

**2. API 代理配置问题**
```nginx
# 检查 nginx.conf 中的代理配置
location /api/ {
    proxy_pass http://backend:8080/api/;  # 确保正确
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

**3. JavaScript 错误**
```javascript
// 检查 API_BASE_URL
const API_BASE_URL = '/api';  # 不是 'http://localhost:8080/api'
```

### 问题 3: 数据未持久化

**症状**:
- 重启容器后数据丢失

**诊断步骤**:
```bash
# 检查卷
docker volume ls
docker volume inspect dockerwork_mysql-data

# 验证卷挂载
docker compose exec mysql df -h /var/lib/mysql
```

**解决方案**:

**1. 未使用命名卷**
```yaml
# 使用命名卷而非匿名卷
volumes:
  - mysql-data:/var/lib/mysql  # 命名卷

volumes:
  mysql-data:
    driver: local
```

**2. 卷被删除**
```bash
# 不要使用 -v 标志除非确实要删除数据
docker compose down    # 保留卷
# 而非
docker compose down -v # 删除卷
```

## 网络问题

### 问题: 容器间无法通信

**诊断步骤**:
```bash
# 测试网络连接
docker compose exec backend ping mysql
docker compose exec backend nc -zv mysql 3306

# 检查网络
docker network ls
docker network inspect dockerwork_ecommerce-network
```

**解决方案**:

**1. 容器不在同一网络**
```yaml
# 确保所有服务在同一网络
services:
  frontend:
    networks:
      - ecommerce-network
  backend:
    networks:
      - ecommerce-network
  mysql:
    networks:
      - ecommerce-network

networks:
  ecommerce-network:
    driver: bridge
```

**2. 使用了 localhost 而非服务名**
```bash
# 错误
DB_HOST=localhost

# 正确
DB_HOST=mysql
```

## 性能问题

### 问题: 响应时间慢

**诊断步骤**:
```bash
# 检查资源使用
docker stats

# Kubernetes
kubectl top pods -n ecommerce
kubectl top nodes

# 测试响应时间
time curl http://localhost:8080/api/products
```

**解决方案**:

**1. 资源不足**
```yaml
# 增加资源限制
resources:
  limits:
    cpu: "2"
    memory: 2Gi
  requests:
    cpu: "1"
    memory: 1Gi
```

**2. 数据库查询慢**
```sql
-- 添加索引
CREATE INDEX idx_category ON products(category);
CREATE INDEX idx_name ON products(name);

-- 分析慢查询
SHOW FULL PROCESSLIST;
```

**3. JVM 调优**
```dockerfile
ENV JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC"
```

## 安全问题

### 问题: 使用默认凭证

**诊断步骤**:
```bash
# 扫描密钥
bash scripts/scan-secrets.sh

# 检查环境变量
docker compose config | grep -i password
```

**解决方案**:

**1. 更新凭证**
```bash
# 生成强密码
openssl rand -base64 32

# 更新 .env 文件
MYSQL_ROOT_PASSWORD=<strong-password>
MYSQL_PASSWORD=<strong-password>

# 重新创建容器
docker compose down -v
docker compose up -d
```

**2. 使用 Docker Secrets (Swarm/Kubernetes)**
```bash
# Docker Swarm
echo "strong-password" | docker secret create db_password -

# Kubernetes
kubectl create secret generic mysql-secret \
  --from-literal=mysql-root-password=<password> \
  -n ecommerce
```

## 获取帮助

如果问题仍未解决:

1. **查看日志**: 始终首先查看日志
2. **搜索文档**: 查看项目文档和 README
3. **检查 GitHub Issues**: 搜索类似问题
4. **提问**: 创建详细的 issue,包括:
   - 错误消息
   - 日志输出
   - 环境信息
   - 重现步骤

## 诊断命令速查表

### Docker Compose

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker compose logs <service>
docker compose logs -f <service>

# 重启服务
docker compose restart <service>

# 重建服务
docker compose up -d --build <service>

# 进入容器
docker compose exec <service> sh

# 查看网络
docker network ls
docker network inspect <network>

# 查看卷
docker volume ls
docker volume inspect <volume>
```

### Kubernetes

```bash
# 查看资源
kubectl get all -n ecommerce
kubectl get pods -n ecommerce
kubectl get svc -n ecommerce

# 查看详细信息
kubectl describe pod <pod> -n ecommerce
kubectl describe svc <service> -n ecommerce

# 查看日志
kubectl logs <pod> -n ecommerce
kubectl logs -f <pod> -n ecommerce
kubectl logs --previous <pod> -n ecommerce

# 进入 Pod
kubectl exec -it <pod> -n ecommerce -- sh

# 查看事件
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# 端口转发
kubectl port-forward <pod> 8080:8080 -n ecommerce

# 查看资源使用
kubectl top pods -n ecommerce
kubectl top nodes
```

## 其他资源

- [Docker 文档](https://docs.docker.com/)
- [Kubernetes 文档](https://kubernetes.io/zh-cn/docs/)
- [部署指南](deployment.md)
- [Kubernetes 部署指南](kubernetes-deployment.md)
