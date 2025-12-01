# Docker 镜像仓库配置指南

## 概述

本项目支持将构建的 Docker 镜像推送到镜像仓库，支持以下仓库类型：
- 本地 Docker Registry
- Docker Hub
- 私有镜像仓库

## 本地 Docker Registry

### 快速设置

```bash
# 运行设置脚本
./ci/setup-docker-registry.sh
```

脚本会自动：
1. 启动本地 Registry 容器 (端口 5000)
2. 配置 Docker 信任本地 Registry
3. 测试镜像推送功能

### 手动设置

```bash
# 1. 启动 Registry 容器
docker run -d \
  --name registry \
  --restart=always \
  -p 5000:5000 \
  -v ~/docker-registry:/var/lib/registry \
  registry:2

# 2. 配置 Docker daemon
sudo nano /etc/docker/daemon.json
```

添加以下内容：
```json
{
  "insecure-registries": ["localhost:5000"]
}
```

```bash
# 3. 重启 Docker
sudo systemctl restart docker

# 4. 验证
curl http://localhost:5000/v2/_catalog
```

### 使用本地 Registry

```bash
# 标记镜像
docker tag my-image:latest localhost:5000/my-image:latest

# 推送镜像
docker push localhost:5000/my-image:latest

# 拉取镜像
docker pull localhost:5000/my-image:latest

# 查看仓库中的镜像
curl http://localhost:5000/v2/_catalog

# 查看镜像的标签
curl http://localhost:5000/v2/my-image/tags/list
```

## Docker Hub

### 配置

1. 在 Docker Hub 创建账号: https://hub.docker.com
2. 创建仓库（可选，公开仓库会自动创建）

### 登录

```bash
# 登录 Docker Hub
docker login

# 输入用户名和密码
```

### 修改 Jenkinsfile

```groovy
environment {
    DOCKER_REGISTRY = 'docker.io'  // Docker Hub
    DOCKER_USERNAME = 'your-username'  // 你的用户名
    // 或使用完整路径
    DOCKER_REGISTRY = 'docker.io/your-username'
}
```

### 推送镜像

```bash
# 标记镜像
docker tag my-image:latest your-username/my-image:latest

# 推送镜像
docker push your-username/my-image:latest
```

## 私有镜像仓库

### Harbor

```bash
# 登录 Harbor
docker login harbor.example.com

# 标记镜像
docker tag my-image:latest harbor.example.com/project/my-image:latest

# 推送镜像
docker push harbor.example.com/project/my-image:latest
```

### 其他私有仓库

修改 Jenkinsfile 中的 `DOCKER_REGISTRY` 环境变量：

```groovy
environment {
    DOCKER_REGISTRY = 'registry.example.com'
    REGISTRY_CREDENTIALS = 'registry-credentials-id'
}
```

## Jenkins 配置

### 添加 Registry 凭据

1. 访问 Jenkins: http://localhost:8090
2. 进入 **Manage Jenkins** > **Manage Credentials**
3. 点击 **(global)** > **Add Credentials**
4. 配置：
   - Kind: **Username with password**
   - Username: 你的用户名
   - Password: 你的密码
   - ID: `docker-registry-credentials`
   - Description: Docker Registry Credentials

### 使用凭据推送

在 Jenkinsfile 中使用凭据：

```groovy
stage('推送镜像到仓库') {
    steps {
        script {
            docker.withRegistry("https://${DOCKER_REGISTRY}", REGISTRY_CREDENTIALS) {
                sh """
                    docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}
                    docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}
                """
            }
        }
    }
}
```

## Pipeline 参数

在 Jenkins 构建时，可以选择是否推送镜像：

- **PUSH_TO_REGISTRY**: 是否推送镜像到仓库
  - `true`: 推送镜像（默认）
  - `false`: 跳过推送

## 镜像命名规范

本项目使用以下命名规范：

```
<registry>/<project-name>-<service>:<tag>

示例:
localhost:5000/docker-ecom-coursework-frontend:1
localhost:5000/docker-ecom-coursework-backend:1
localhost:5000/docker-ecom-coursework-frontend:latest
localhost:5000/docker-ecom-coursework-backend:latest
```

## 查看推送的镜像

### 本地 Registry

```bash
# 查看所有镜像
curl http://localhost:5000/v2/_catalog

# 查看特定镜像的标签
curl http://localhost:5000/v2/docker-ecom-coursework-frontend/tags/list
curl http://localhost:5000/v2/docker-ecom-coursework-backend/tags/list
```

### Docker Hub

访问: https://hub.docker.com/repositories

### Harbor

访问 Harbor Web UI 查看

## 从仓库拉取镜像

```bash
# 本地 Registry
docker pull localhost:5000/docker-ecom-coursework-frontend:1

# Docker Hub
docker pull your-username/docker-ecom-coursework-frontend:1

# 私有仓库
docker pull registry.example.com/docker-ecom-coursework-frontend:1
```

## 在 Kubernetes 中使用

修改 Kubernetes 部署文件，使用仓库中的镜像：

```yaml
spec:
  containers:
  - name: frontend
    image: localhost:5000/docker-ecom-coursework-frontend:1
    imagePullPolicy: Always
```

如果使用私有仓库，需要创建 Secret：

```bash
# 创建 Docker Registry Secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com \
  -n ecommerce

# 在部署中使用
spec:
  imagePullSecrets:
  - name: regcred
  containers:
  - name: frontend
    image: registry.example.com/docker-ecom-coursework-frontend:1
```

## 清理镜像

### 本地 Registry

```bash
# 删除镜像（需要启用 Registry 的删除功能）
# 1. 获取镜像的 digest
curl -I -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  http://localhost:5000/v2/docker-ecom-coursework-frontend/manifests/1

# 2. 删除镜像
curl -X DELETE http://localhost:5000/v2/docker-ecom-coursework-frontend/manifests/<digest>

# 3. 运行垃圾回收
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml
```

### Docker Hub

通过 Web UI 删除镜像

## 故障排查

### 推送失败: x509 certificate

```bash
# 配置 insecure-registries
sudo nano /etc/docker/daemon.json
```

添加：
```json
{
  "insecure-registries": ["localhost:5000"]
}
```

```bash
sudo systemctl restart docker
```

### 推送失败: unauthorized

```bash
# 检查登录状态
docker login localhost:5000

# 或使用凭据
docker login -u username -p password localhost:5000
```

### Registry 无法访问

```bash
# 检查 Registry 容器状态
docker ps | grep registry

# 查看日志
docker logs registry

# 重启 Registry
docker restart registry
```

### Jenkins 推送失败

1. 检查 Jenkins 容器网络配置
2. 确认 Registry 凭据配置正确
3. 查看 Jenkins 构建日志

## 最佳实践

1. **使用版本标签**: 始终使用具体的版本号，避免只使用 `latest`
2. **定期清理**: 定期清理旧的镜像以节省空间
3. **安全配置**: 生产环境使用 HTTPS 和认证
4. **备份**: 定期备份 Registry 数据
5. **监控**: 监控 Registry 的磁盘使用和性能

## 参考资料

- [Docker Registry 官方文档](https://docs.docker.com/registry/)
- [Docker Hub 文档](https://docs.docker.com/docker-hub/)
- [Harbor 文档](https://goharbor.io/docs/)
