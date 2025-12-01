# Docker 电商数据管理系统

一个容器化的三层电商应用，展示了使用 Docker、Kubernetes 和 CI/CD 流水线的现代 DevOps 实践。

## 概述

本项目实现了完整的容器化电商系统，包括：
- 多阶段 Dockerfile 优化
- Kubernetes 容器编排
- 蓝绿部署策略
- Jenkins CI/CD 自动化
- APM 监控系统
- 基于属性的测试

## 系统架构

系统由三个容器化服务组成：

1. **前端服务**: 基于 Nginx 的静态 Web 服务器，提供产品目录页面
2. **后端 API 服务**: Spring Boot REST API，提供产品管理的 CRUD 操作
3. **数据库服务**: MySQL 数据库，提供持久化存储

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes 集群                           │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              命名空间: ecommerce                        │ │
│  │                                                          │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌───────┐│ │
│  │  │   前端       │─────>│   后端       │─────>│ MySQL ││ │
│  │  │   (Nginx)    │      │ (Spring Boot)│      │  DB   ││ │
│  │  │   2 副本     │      │   2 副本     │      │ 1 副本││ │
│  │  └──────────────┘      └──────────────┘      └───────┘│ │
│  │                                                          │ │
│  │  蓝绿部署: Blue/Green 环境独立运行                      │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 技术栈

**应用层**
- 前端: HTML5、CSS3、JavaScript、Nginx Alpine
- 后端: Java 17、Spring Boot 3.x、Maven
- 数据库: MySQL 8.0

**容器化与编排**
- Docker、Docker Compose
- Kubernetes (Minikube)
- 蓝绿部署策略

**CI/CD**
- Jenkins Pipeline
- 自动化测试
- 代码覆盖率报告 (JaCoCo)

**监控**
- Prometheus
- Grafana
- Alertmanager

**测试**
- JUnit 5
- jqwik (基于属性的测试)
- TestContainers

## 前置要求

- Docker 20.10+
- Minikube 1.28+
- Java 17+
- Maven 3.9+
- Git

## 快速开始

### 方式一: Docker Compose (本地开发)

```bash
# 1. 克隆仓库
git clone <repository-url>
cd docker-ecom-coursework

# 2. 启动所有服务
docker-compose up --build

# 3. 访问应用
# 前端: http://localhost:80
# 后端 API: http://localhost:8080/api/products
```

### 方式二: Kubernetes + Jenkins (生产环境)

```bash
# 1. 启动 Minikube
minikube start

# 2. 设置 Docker Registry (可选)
./ci/setup-docker-registry.sh

# 3. 启动 Jenkins
./ci/run-jenkins-local.sh

# 4. 配置 Jenkins 访问 Kubernetes
./ci/setup-jenkins-k8s.sh

# 5. 访问 Jenkins
# 打开 http://localhost:8090
# 输入初始管理员密码（脚本会显示）

# 6. 运行 Pipeline
# 进入 docker-ecom-coursework 任务
# 点击 "Build with Parameters"
# 选择参数后点击 "Build"
```

## 项目结构

```
docker-ecom-coursework/
├── frontend/                 # 前端服务
│   ├── Dockerfile           # 多阶段构建配置
│   ├── nginx.conf           # Nginx 配置
│   └── html/                # 静态资源
├── backend/                  # 后端服务
│   ├── Dockerfile           # 多阶段构建配置
│   ├── pom.xml              # Maven 配置
│   └── src/                 # Java 源代码
├── database/                 # 数据库
│   ├── Dockerfile           # MySQL 配置
│   └── init.sql             # 初始化脚本
├── k8s/                      # Kubernetes 配置
│   ├── backend/             # 后端 K8s 资源
│   ├── frontend/            # 前端 K8s 资源
│   ├── database/            # 数据库 K8s 资源
│   ├── blue-green/          # 蓝绿部署配置
│   ├── deploy.sh            # 部署脚本
│   └── README.md            # K8s 部署文档
├── monitoring/               # 监控配置
│   ├── prometheus/          # Prometheus 配置
│   ├── grafana/             # Grafana 配置
│   └── alertmanager/        # Alertmanager 配置
├── ci/                       # CI/CD 脚本
│   ├── run-jenkins-local.sh      # 启动 Jenkins
│   ├── setup-jenkins-k8s.sh      # 配置 K8s 访问
│   ├── setup-minikube.sh         # 设置 Minikube
│   ├── k8s-access.sh             # K8s 服务访问
│   └── install-k8s-plugins.sh    # 安装 Jenkins 插件
├── docs/                     # 文档
├── docker-compose.yml        # Docker Compose 配置
├── docker-compose.monitoring.yml  # 监控栈配置
├── Jenkinsfile              # Jenkins Pipeline 定义
└── README.md                # 本文件
```

## Jenkins CI/CD Pipeline

### Pipeline 阶段

1. **环境信息** - 显示构建参数和环境配置
2. **代码检出** - 使用本地挂载的代码
3. **构建阶段** - 构建后端应用和 Docker 镜像
4. **推送镜像到仓库** - 推送镜像到 Docker Registry
5. **单元测试** - 运行 JUnit 单元测试
6. **集成测试** - 运行属性测试
7. **代码覆盖率报告** - 生成 JaCoCo 覆盖率报告
8. **Kubernetes 蓝绿部署** - 部署到指定环境 (blue/green)
9. **健康检查** - 验证服务状态和启动端口转发
10. **部署监控系统** - 可选部署 Prometheus + Grafana
11. **部署验证** - 测试服务可访问性

### 构建参数

- **K8S_VERSION**: 选择部署环境 (blue 或 green)
- **SWITCH_TRAFFIC**: 是否自动切换流量到新环境
- **SKIP_TESTS**: 是否跳过测试阶段 (快速部署)
- **DEPLOY_MONITORING**: 是否部署监控系统
- **PUSH_TO_REGISTRY**: 是否推送镜像到仓库 (默认: true)

### 使用示例

```bash
# 部署到 blue 环境
K8S_VERSION=blue
SWITCH_TRAFFIC=false
SKIP_TESTS=false
DEPLOY_MONITORING=false

# 部署到 green 环境并自动切换流量
K8S_VERSION=green
SWITCH_TRAFFIC=true
SKIP_TESTS=false
DEPLOY_MONITORING=true
```

## Kubernetes 蓝绿部署

### 蓝绿部署策略

蓝绿部署维护两个完全相同的生产环境：
- **Blue 环境**: 当前生产环境
- **Green 环境**: 新版本部署和测试环境

### 部署流程

1. **部署新版本到 Green** - 在不影响生产的情况下部署
2. **测试 Green 环境** - 验证新版本功能正常
3. **切换流量** - 原子性地将流量切换到 Green
4. **监控** - 观察新版本运行状态
5. **回滚** (如需要) - 快速切换回 Blue 环境

### 手动操作

```bash
# 部署到 blue 环境
cd k8s/blue-green
./deploy-blue-green.sh blue

# 部署到 green 环境
./deploy-blue-green.sh green

# 切换流量到 green
./switch-traffic.sh green

# 回滚到 blue
./switch-traffic.sh blue
```

## API 端点

### 产品管理 API

| 方法 | 端点 | 描述 | 响应 |
|------|------|------|------|
| GET | /api/products | 获取所有产品 | 200 + Product[] |
| GET | /api/products/{id} | 获取单个产品 | 200 + Product |
| POST | /api/products | 创建产品 | 201 + Product |
| PUT | /api/products/{id} | 更新产品 | 200 + Product |
| DELETE | /api/products/{id} | 删除产品 | 204 |

### 健康检查

| 端点 | 描述 |
|------|------|
| /actuator/health | 后端健康检查 |
| /health | 前端健康检查 |

### 产品对象示例

```json
{
  "id": 1,
  "name": "产品名称",
  "description": "产品描述",
  "price": 99.99,
  "stockQuantity": 100,
  "category": "电子产品",
  "imageUrl": "https://example.com/image.jpg",
  "createdAt": "2025-11-24T10:00:00",
  "updatedAt": "2025-11-24T10:00:00"
}
```

## 测试

### 运行测试

```bash
# 单元测试
cd backend
mvn test

# 集成测试
mvn verify

# 属性测试
mvn test -Dtest=*PropertyTest

# 生成覆盖率报告
mvn jacoco:report
```

### 测试类型

1. **单元测试** - 测试单个组件功能
2. **属性测试** - 使用 jqwik 进行随机输入测试 (100+ 次迭代)
3. **集成测试** - 使用 TestContainers 测试服务交互
4. **端到端测试** - 验证完整业务流程

### 覆盖率报告

Jenkins Pipeline 自动生成 JaCoCo 覆盖率报告：
- 报告位置: `backend/target/site/jacoco/index.html`
- Jenkins 中查看: Build > JaCoCo Coverage Report

## 监控

### Prometheus + Grafana

监控系统提供：
- 实时指标收集
- 可视化仪表板
- 告警配置
- 容器资源监控

### 访问监控服务

```bash
# 通过 Docker Compose
docker-compose -f docker-compose.monitoring.yml up -d

# 访问地址
# Grafana: http://localhost:3000 (admin/admin)
# Prometheus: http://localhost:9090
# Alertmanager: http://localhost:9093
```

### Kubernetes 监控

```bash
# 部署监控到 Kubernetes
kubectl create namespace monitoring
kubectl apply -f monitoring/prometheus/ -n monitoring
kubectl apply -f monitoring/grafana/ -n monitoring

# 访问服务
kubectl port-forward -n monitoring service/grafana 3000:3000
kubectl port-forward -n monitoring service/prometheus 9090:9090
```

## 常用命令

### Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重建并启动
docker-compose up --build -d
```

### Kubernetes

```bash
# 查看所有资源
kubectl get all -n ecommerce

# 查看 Pod 日志
kubectl logs -f deployment/backend -n ecommerce

# 扩展副本数
kubectl scale deployment/backend --replicas=3 -n ecommerce

# 查看服务
kubectl get services -n ecommerce

# 端口转发
kubectl port-forward -n ecommerce service/frontend-service 8082:80
```

### Jenkins

```bash
# 启动 Jenkins
./ci/run-jenkins-local.sh

# 查看 Jenkins 日志
docker logs -f jenkins-local

# 停止 Jenkins
docker stop jenkins-local

# 重启 Jenkins
docker restart jenkins-local
```

## 环境变量

主要环境变量配置 (`.env` 文件):

```bash
# 数据库配置
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=ecommerce
MYSQL_USER=ecommerce_user
MYSQL_PASSWORD=ecommerce_password

# 后端配置
DB_HOST=database
DB_PORT=3306
DB_NAME=ecommerce
DB_USER=ecommerce_user
DB_PASSWORD=ecommerce_password
SPRING_PROFILES_ACTIVE=dev
```

## 故障排查

### 常见问题

**1. Jenkins 无法访问 Kubernetes**

```bash
# 重新配置 Kubernetes 访问
./ci/setup-jenkins-k8s.sh

# 验证配置
docker exec jenkins-local kubectl get nodes
```

**2. Pod 无法启动**

```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n ecommerce

# 查看日志
kubectl logs <pod-name> -n ecommerce

# 检查镜像
minikube image ls | grep ecommerce
```

**3. 服务无法访问**

```bash
# 检查服务状态
kubectl get services -n ecommerce

# 重启端口转发
./ci/k8s-access.sh

# 检查 Pod 健康
kubectl get pods -n ecommerce
```

**4. 数据库连接失败**

```bash
# 检查数据库 Pod
kubectl get pods -n ecommerce -l app=mysql

# 查看数据库日志
kubectl logs -f statefulset/mysql -n ecommerce

# 测试连接
kubectl exec -it mysql-0 -n ecommerce -- mysql -u root -p
```

## 安全注意事项

**警告**: 本项目包含用于开发的硬编码凭证，不应在生产环境使用。

### 生产部署前必须:

1. 更改所有默认密码
2. 使用 Kubernetes Secrets 管理敏感信息
3. 启用 TLS/SSL
4. 配置网络策略
5. 实施访问控制
6. 定期更新依赖

详细安全建议请参阅 `docs/` 目录中的安全文档。

## 文档

### 核心文档
- [架构文档](docs/architecture.md) - 系统架构和设计决策
- [部署指南](docs/deployment.md) - 详细部署说明
- [API 文档](docs/api.md) - REST API 参考
- [故障排查](docs/troubleshooting.md) - 常见问题解决

### Kubernetes 文档
- [K8s 部署指南](k8s/README.md) - Kubernetes 部署详解
- [蓝绿部署](k8s/blue-green/README.md) - 蓝绿部署策略
- [监控设置](docs/monitoring-setup.md) - 监控系统配置

### CI/CD 文档
- [CI/CD 设置](docs/CI_CD_SETUP.md) - Jenkins Pipeline 配置
- [Docker Registry](docs/docker-registry.md) - 镜像仓库配置指南
- [Dockerfile 优化](docs/dockerfile-optimizations.md) - 镜像优化技巧

## 贡献

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 提交消息规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## 许可证

本项目用于教育和演示目的。

## 联系方式

如有问题或建议，请提交 Issue。

---

**版本**: 1.0.0  
**最后更新**: 2025-12-01
