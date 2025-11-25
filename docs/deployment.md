# 部署指南

## 目录
1. [概述](#概述)
2. [环境准备](#环境准备)
3. [本地部署](#本地部署)
4. [生产部署](#生产部署)
5. [云平台部署](#云平台部署)
6. [部署验证](#部署验证)
7. [常见问题](#常见问题)

## 概述

本指南提供了将电商系统部署到不同环境的详细说明,包括本地开发、预发布和生产环境。

### 部署选项

- **Docker Compose**:适用于本地开发和小型部署
- **Kubernetes**:适用于生产环境和可扩展部署
- **云平台**:AWS、Azure、GCP 等云服务提供商

## 环境准备

### 系统要求

**最低要求**:
- CPU:2 核心
- 内存:4GB RAM
- 存储:10GB 可用空间
- 操作系统:Linux、macOS 或 Windows 10/11

**推荐配置**:
- CPU:4+ 核心
- 内存:8GB+ RAM
- 存储:20GB+ 可用空间
- SSD 存储

### 软件依赖

**必需**:
- Docker 20.10 或更高版本
- Docker Compose 2.0 或更高版本

**可选**:
- kubectl(用于 Kubernetes 部署)
- Git(用于版本控制)
- Make(用于自动化脚本)

### 安装 Docker

**Ubuntu/Debian**:
```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加 Docker GPG 密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 设置稳定版仓库
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

**macOS**:
```bash
# 使用 Homebrew
brew install --cask docker

# 或下载 Docker Desktop
# https://www.docker.com/products/docker-desktop
```

**Windows**:
```powershell
# 下载并安装 Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### 验证安装

```bash
# 检查 Docker 版本
docker --version

# 检查 Docker Compose 版本
docker compose version

# 测试 Docker
docker run hello-world
```

## 本地部署

### 快速开始

1. **克隆仓库**:
```bash
git clone <repository-url>
cd dockerwork
```

2. **配置环境变量**(可选):
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量
nano .env
```

3. **启动所有服务**:
```bash
# 构建并启动
docker compose up --build

# 或在后台运行
docker compose up -d --build
```

4. **验证部署**:
```bash
# 检查服务状态
docker compose ps

# 查看日志
docker compose logs

# 测试访问
curl http://localhost:80
curl http://localhost:8080/api/products
```

5. **停止服务**:
```bash
# 停止服务
docker compose down

# 停止并删除卷
docker compose down -v
```

### 开发模式部署

开发模式提供代码热重载和详细日志:

```bash
# 使用开发配置
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# 挂载源代码卷以支持热重载
# 启用调试端口
# 增加日志详细程度
```

### 本地测试

```bash
# 运行单元测试
cd backend
mvn test

# 运行集成测试
mvn verify

# 运行基于属性的测试
mvn test -Dtest=*PropertyTest

# 检查代码覆盖率
mvn clean test jacoco:report
# 打开 target/site/jacoco/index.html
```

## 生产部署

### 准备生产环境

1. **更新配置**:
```bash
# 编辑生产配置
nano docker-compose.prod.yml
```

2. **设置秘密**:
```bash
# 使用强密码
# 不要使用默认凭证
# 使用环境变量或 Docker secrets

# 创建 Docker secrets
echo "strong_db_password" | docker secret create db_password -
echo "strong_root_password" | docker secret create db_root_password -
```

3. **配置资源限制**:
```yaml
# 在 docker-compose.prod.yml 中
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

### 构建生产镜像

```bash
# 构建优化的生产镜像
docker compose -f docker-compose.prod.yml build

# 推送到容器仓库
docker compose -f docker-compose.prod.yml push
```

### 部署到生产服务器

**使用 Docker Compose**:
```bash
# 在生产服务器上
cd /opt/ecommerce

# 拉取最新镜像
docker compose -f docker-compose.prod.yml pull

# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 验证部署
docker compose -f docker-compose.prod.yml ps
```

**使用 Docker Swarm**:
```bash
# 初始化 Swarm
docker swarm init

# 部署堆栈
docker stack deploy -c docker-compose.prod.yml ecommerce

# 查看服务
docker stack services ecommerce

# 扩展服务
docker service scale ecommerce_backend=3
docker service scale ecommerce_frontend=3
```

### 生产环境最佳实践

1. **使用反向代理**:
```nginx
# Nginx 反向代理配置
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

2. **启用 SSL/TLS**:
```bash
# 使用 Let's Encrypt
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

3. **配置防火墙**:
```bash
# UFW 示例
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

4. **设置日志轮转**:
```bash
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

5. **配置监控**:
```bash
# 部署 Prometheus 和 Grafana
docker compose -f monitoring/docker-compose.yml up -d
```

## 云平台部署

### AWS 部署

**使用 ECS**:
```bash
# 安装 AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 配置凭证
aws configure

# 创建 ECR 仓库
aws ecr create-repository --repository-name ecommerce-frontend
aws ecr create-repository --repository-name ecommerce-backend

# 推送镜像
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag ecommerce-frontend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/ecommerce-frontend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/ecommerce-frontend:latest

# 创建 ECS 集群和服务
# 使用 AWS 控制台或 CloudFormation
```

**使用 EKS**:
```bash
# 安装 eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# 创建集群
eksctl create cluster --name ecommerce-cluster --region us-east-1

# 部署应用
kubectl apply -f k8s/
```

### Azure 部署

**使用 ACI**:
```bash
# 安装 Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 登录
az login

# 创建资源组
az group create --name ecommerce-rg --location eastus

# 创建 ACR
az acr create --resource-group ecommerce-rg --name ecommerceacr --sku Basic

# 推送镜像
az acr login --name ecommerceacr
docker tag ecommerce-frontend:latest ecommerceacr.azurecr.io/ecommerce-frontend:latest
docker push ecommerceacr.azurecr.io/ecommerce-frontend:latest

# 部署容器实例
az container create --resource-group ecommerce-rg --name ecommerce-frontend --image ecommerceacr.azurecr.io/ecommerce-frontend:latest --dns-name-label ecommerce-frontend --ports 80
```

**使用 AKS**:
```bash
# 创建 AKS 集群
az aks create --resource-group ecommerce-rg --name ecommerce-cluster --node-count 2 --enable-addons monitoring --generate-ssh-keys

# 获取凭证
az aks get-credentials --resource-group ecommerce-rg --name ecommerce-cluster

# 部署应用
kubectl apply -f k8s/
```

### GCP 部署

**使用 Cloud Run**:
```bash
# 安装 gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# 初始化
gcloud init

# 构建并推送镜像
gcloud builds submit --tag gcr.io/PROJECT_ID/ecommerce-frontend

# 部署到 Cloud Run
gcloud run deploy ecommerce-frontend --image gcr.io/PROJECT_ID/ecommerce-frontend --platform managed --region us-central1 --allow-unauthenticated
```

**使用 GKE**:
```bash
# 创建 GKE 集群
gcloud container clusters create ecommerce-cluster --num-nodes=2 --zone=us-central1-a

# 获取凭证
gcloud container clusters get-credentials ecommerce-cluster --zone=us-central1-a

# 部署应用
kubectl apply -f k8s/
```

## Kubernetes 部署

详细的 Kubernetes 部署说明请参阅 [k8s/README.md](../k8s/README.md)。

### 快速部署

```bash
# 进入 k8s 目录
cd k8s

# 运行部署脚本
./deploy.sh

# 或手动部署
kubectl apply -f namespace.yaml
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/
```

### 访问应用

```bash
# 使用端口转发
kubectl port-forward -n ecommerce service/frontend-service 8080:80

# 或使用 Ingress
kubectl apply -f ingress.yaml
```

## 部署验证

### 健康检查

```bash
# 检查前端
curl http://localhost:80/health

# 检查后端
curl http://localhost:8080/actuator/health

# 检查数据库
docker compose exec mysql mysqladmin ping -h localhost -u root -p
```

### 功能测试

```bash
# 测试 API 端点
curl http://localhost:8080/api/products

# 测试创建产品
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试产品",
    "description": "测试描述",
    "price": 99.99,
    "stockQuantity": 10,
    "category": "测试"
  }'

# 测试前端
curl http://localhost:80
```

### 性能测试

```bash
# 使用 Apache Bench
ab -n 1000 -c 10 http://localhost:8080/api/products

# 使用 wrk
wrk -t4 -c100 -d30s http://localhost:8080/api/products
```

### 日志检查

```bash
# Docker Compose
docker compose logs frontend
docker compose logs backend
docker compose logs mysql

# Kubernetes
kubectl logs -n ecommerce -l app=frontend
kubectl logs -n ecommerce -l app=backend
kubectl logs -n ecommerce -l app=mysql
```

## 常见问题

### 端口冲突

**问题**:端口 80、8080 或 3306 已被占用

**解决方案**:
```bash
# 查找占用端口的进程
sudo lsof -i :80
sudo lsof -i :8080
sudo lsof -i :3306

# 停止进程或修改端口映射
# 编辑 docker-compose.yml
ports:
  - "8081:80"  # 使用不同的主机端口
```

### 数据库连接失败

**问题**:后端无法连接到数据库

**解决方案**:
```bash
# 检查数据库是否运行
docker compose ps mysql

# 检查数据库日志
docker compose logs mysql

# 验证网络连接
docker compose exec backend nc -zv mysql 3306

# 检查环境变量
docker compose exec backend env | grep DB_
```

### 镜像构建失败

**问题**:Docker 镜像构建失败

**解决方案**:
```bash
# 清理 Docker 缓存
docker builder prune -a

# 使用 --no-cache 重新构建
docker compose build --no-cache

# 检查 Dockerfile 语法
docker build --progress=plain -t test ./backend
```

### 内存不足

**问题**:容器因内存不足而崩溃

**解决方案**:
```bash
# 增加 Docker 内存限制
# Docker Desktop: Settings → Resources → Memory

# 调整容器内存限制
# 编辑 docker-compose.yml
services:
  backend:
    mem_limit: 1g
    mem_reservation: 512m
```

### 数据持久性问题

**问题**:重启后数据丢失

**解决方案**:
```bash
# 确保使用命名卷
volumes:
  mysql-data:
    driver: local

# 检查卷
docker volume ls
docker volume inspect dockerwork_mysql-data

# 备份数据
docker compose exec mysql mysqldump -u root -p ecommerce > backup.sql
```

## 回滚策略

### Docker Compose 回滚

```bash
# 停止当前版本
docker compose down

# 拉取之前的镜像版本
docker pull ecommerce-backend:previous-version

# 启动之前的版本
docker compose up -d
```

### Kubernetes 回滚

```bash
# 查看部署历史
kubectl rollout history deployment/backend -n ecommerce

# 回滚到上一个版本
kubectl rollout undo deployment/backend -n ecommerce

# 回滚到特定版本
kubectl rollout undo deployment/backend --to-revision=2 -n ecommerce
```

## 备份和恢复

### 数据库备份

```bash
# 创建备份
docker compose exec mysql mysqldump -u root -p ecommerce > backup-$(date +%Y%m%d).sql

# 恢复备份
docker compose exec -T mysql mysql -u root -p ecommerce < backup-20250101.sql
```

### 卷备份

```bash
# 备份卷数据
docker run --rm -v dockerwork_mysql-data:/source -v $(pwd):/backup alpine tar czf /backup/mysql-data-backup.tar.gz -C /source .

# 恢复卷数据
docker run --rm -v dockerwork_mysql-data:/target -v $(pwd):/backup alpine tar xzf /backup/mysql-data-backup.tar.gz -C /target
```

## 监控和维护

### 设置监控

```bash
# 部署 Prometheus
docker compose -f monitoring/docker-compose.yml up -d

# 访问 Grafana
http://localhost:3000
# 默认凭证: admin/admin
```

### 定期维护

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune

# 更新镜像
docker compose pull
docker compose up -d
```

## 其他资源

- [Docker 文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Kubernetes 文档](https://kubernetes.io/zh-cn/docs/)
- [部署检查清单](../k8s/DEPLOYMENT_CHECKLIST.md)
- [故障排查指南](troubleshooting.md)
