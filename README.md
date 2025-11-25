# Docker 电商数据管理系统

一个容器化的三层电商应用，展示了使用 Docker、Docker Compose 和 CI/CD 流水线的现代 DevOps 实践。

## 概述

本项目展示了全面的容器化技能，包括：
- 多阶段 Dockerfile 创建和优化
- Docker Compose 编排
- 容器网络和卷管理
- CI/CD 流水线实施
- 基于属性的测试以验证正确性

## 架构

系统由三个容器化服务组成：

1. **前端服务**：基于 Nginx 的静态 Web 服务器，提供产品目录页面
2. **后端 API 服务**：Spring Boot REST API，提供产品管理的 CRUD 操作
3. **数据库服务**：MySQL 数据库，提供持久化存储

```
┌─────────────────────────────────────────────────────────────┐
│                        主机                                  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker 自定义网络                          │ │
│  │                                                          │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌───────┐│ │
│  │  │   前端       │─────▶│   后端       │─────▶│ MySQL ││ │
│  │  │   (Nginx)    │      │ (Spring Boot)│      │  DB   ││ │
│  │  │   端口 8081    │      │  端口 8080   │      │ 3306  ││ │
│  │  └──────────────┘      └──────────────┘      └───────┘│ │
│  │                                                          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 技术栈

- **前端**：HTML5、CSS3、JavaScript、Nginx Alpine
- **后端**：Java 17、Spring Boot 3.x、Maven
- **数据库**：MySQL 8.0
- **容器化**：Docker、Docker Compose
- **测试**：JUnit 5、jqwik（基于属性的测试）、TestContainers
- **CI/CD**：Jenkins 或 GitLab CI

## 前置要求

- Docker 20.10 或更高版本
- Docker Compose 2.0 或更高版本
- Git

## 快速开始

### 本地开发

1. 克隆仓库：
```bash
git clone <repository-url>
cd ecommerce-docker-system
```

2. 配置环境变量（可选）：
```bash
# .env 文件已存在，包含开发环境的默认配置
# 如需自定义，可以编辑 .env 文件
cp .env.example .env  # 可选：从模板创建
nano .env             # 编辑环境变量
```

3. 启动所有服务：
```bash
docker-compose up --build
```

3. 访问应用：
   - 前端：http://localhost:80
   - 后端 API：http://localhost:8080/api/products
   - 数据库：localhost:3306（如需直接访问）

4. 停止所有服务：
```bash
docker-compose down
```

5. 停止并删除卷（全新开始）：
```bash
docker-compose down -v
```

## 项目结构

```
ecommerce-docker-system/
├── frontend/               # 前端服务
│   ├── Dockerfile
│   ├── nginx.conf
│   └── html/
│       ├── index.html
│       ├── product-detail.html
│       ├── css/
│       │   └── styles.css
│       └── js/
│           └── app.js
├── backend/                # 后端 API 服务
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── java/
│       │   │   └── com/ecommerce/
│       │   │       ├── EcommerceApplication.java
│       │   │       ├── controller/
│       │   │       ├── service/
│       │   │       ├── repository/
│       │   │       └── model/
│       │   └── resources/
│       │       └── application.yml
│       └── test/
│           └── java/
│               └── com/ecommerce/
├── database/               # 数据库初始化
│   └── init.sql
├── k8s/                    # Kubernetes 清单（高级）
│   ├── frontend/
│   ├── backend/
│   └── database/
├── docs/                   # 文档
├── docker-compose.yml      # 开发编排
├── docker-compose.prod.yml # 生产编排
├── .gitignore
├── .dockerignore
└── README.md
```

## API 端点

### 产品 API

| 方法 | 端点 | 描述 | 响应 |
|------|------|------|------|
| GET | /api/products | 列出所有产品 | 200 + Product[] |
| GET | /api/products/{id} | 根据 ID 获取产品 | 200 + Product |
| POST | /api/products | 创建新产品 | 201 + Product |
| PUT | /api/products/{id} | 更新产品 | 200 + Product |
| DELETE | /api/products/{id} | 删除产品 | 204 |

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

## 开发

### 构建单个服务

```bash
# 构建前端
docker build -t ecommerce-frontend ./frontend

# 构建后端
docker build -t ecommerce-backend ./backend

# 构建所有服务
docker-compose build
```

### 运行测试

```bash
# 运行后端单元测试
cd backend
mvn test

# 运行后端集成测试
mvn verify

# 运行基于属性的测试
mvn test -Dtest=*PropertyTest
```

### 查看日志

```bash
# 查看所有日志
docker-compose logs

# 查看特定服务日志
docker-compose logs frontend
docker-compose logs backend
docker-compose logs mysql

# 实时跟踪日志
docker-compose logs -f
```

## 配置

### 环境变量

项目使用 `.env` 文件管理环境变量。所有敏感配置都从 `.env` 文件中读取，避免硬编码。

**主要环境变量：**

- `MYSQL_ROOT_PASSWORD`：MySQL root 密码
- `MYSQL_DATABASE`：数据库名称（默认：ecommerce）
- `MYSQL_USER`：MySQL 应用用户
- `MYSQL_PASSWORD`：应用用户密码
- `DB_HOST`：数据库主机名（默认：database）
- `DB_PORT`：数据库端口（默认：3306）
- `DB_NAME`：数据库名称（默认：ecommerce）
- `DB_USER`：后端连接使用的数据库用户
- `DB_PASSWORD`：后端连接使用的数据库密码
- `SPRING_PROFILES_ACTIVE`：Spring 活动配置文件（dev/prod）

详细配置说明请参阅 [ENV_SETUP.md](ENV_SETUP.md)

## 测试策略

项目实施了全面的测试：

1. **单元测试**：隔离测试单个组件
2. **基于属性的测试**：在随机输入上验证正确性属性（100+ 次迭代）
3. **集成测试**：使用 TestContainers 测试服务通信
4. **端到端测试**：验证完整工作流

### 基于属性的测试

本项目使用 jqwik 进行基于属性的测试以验证正确性属性：

- 产品检索完整性
- 产品创建持久性
- 产品更新正确性
- 产品删除完整性
- 跨容器生命周期的卷持久性
- 端到端数据流完整性

## CI/CD 流水线

项目包含三个平台的全面 CI/CD 流水线配置：

- **GitLab CI**（`.gitlab-ci.yml`）- 用于 GitLab 仓库
- **Jenkins**（`Jenkinsfile`）- 用于 Jenkins 自动化服务器
- **GitHub Actions**（`.github/workflows/ci-cd.yml`）- 用于 GitHub 仓库

### 流水线阶段

1. **构建阶段**：为所有服务构建 Docker 镜像
2. **测试阶段**：运行单元、集成和属性测试，生成覆盖率报告
3. **推送阶段**：使用适当的标签将镜像推送到容器仓库
4. **部署阶段**：部署到预发布/生产环境，需要手动批准

### 快速开始

选择您的平台并按照设置：

```bash
# 验证 CI/CD 配置
.ci/validate-pipelines.sh

# 查看快速入门指南
cat .ci/QUICK_START.md
```

详细设置说明，请参阅：
- [CI/CD 设置指南](docs/CI_CD_SETUP.md)
- [CI/CD README](CI_CD_README.md)
- [快速入门](.ci/QUICK_START.md)

## 生产部署

生产部署：

```bash
# 构建生产镜像
docker-compose -f docker-compose.prod.yml build

# 推送到仓库
docker-compose -f docker-compose.prod.yml push

# 部署
docker-compose -f docker-compose.prod.yml up -d
```

## 高级功能

### Kubernetes 部署

`k8s/` 目录中提供了用于生产编排的 Kubernetes 清单。

**快速开始：**
```bash
# 构建并加载镜像（针对 minikube/kind）
cd k8s
./deploy.sh

# 访问应用
kubectl port-forward -n ecommerce service/frontend-service 8080:80
# 打开 http://localhost:8080
```

**文档：**
- [Kubernetes 部署指南（中文）](k8s/README_CN.md) - 综合部署说明
- [快速入门指南（中文）](k8s/QUICK_START_CN.md) - 常见任务快速参考
- [Kubernetes README（英文）](k8s/README.md) - 详细清单文档

**特性：**
- 数据库使用 StatefulSet 和持久化存储
- 前端和后端使用 Deployment 和健康检查
- 使用 ConfigMap 和 Secret 进行配置管理
- 支持水平扩展
- 资源限制和请求
- 自动化部署脚本

### 监控

可选的 APM 监控，使用 Prometheus/Grafana 或 SkyWalking 实现可观测性。

### 部署策略

支持蓝绿和金丝雀部署策略，实现零停机发布。

## 安全

### ⚠️ 重要安全提示

**此仓库包含仅用于开发目的的硬编码凭证。**

`docker-compose.yml` 中的默认配置使用硬编码密码，这些密码**不安全**，**绝不**应在生产环境中使用。

### 本地开发

1. 复制 `.env.example` 到 `.env`：
   ```bash
   cp .env.example .env
   ```

2. 更新 `.env` 中的密码（本地开发可选）

3. `.env` 文件已被 gitignore，不会被提交

### 生产部署

**关键**：在部署到生产之前：

1. ✅ 使用强且唯一的密码（16+ 字符）
2. ✅ 使用 Docker secrets 或外部密钥管理（HashiCorp Vault、AWS Secrets Manager）
3. ✅ 绝不使用此仓库的默认密码
4. ✅ 定期轮换凭证
5. ✅ 查看 [SECURITY_AUDIT.md](SECURITY_AUDIT.md) 获取详细建议

### 扫描密钥

运行密钥扫描器检查硬编码凭证：

```bash
bash scripts/scan-secrets.sh
```

此脚本将：
- 扫描硬编码密码和 API 密钥
- 检查意外提交的密钥文件
- 验证 .gitignore 配置
- 提供修复建议

### 已知安全问题（仅开发）

以下文件包含用于开发的硬编码凭证：
- `docker-compose.yml` - 数据库密码
- `backend/src/main/resources/application.yml` - 默认回退密码

这些已在 [SECURITY_AUDIT.md](SECURITY_AUDIT.md) 中记录，并提供了修复步骤。

## 故障排查

### 常见问题

**服务无法通信：**
- 验证所有服务在同一 Docker 网络上
- 检查 docker-compose.yml 中的服务名称是否匹配

**数据库连接失败：**
- 确保数据库健康检查在后端启动前通过
- 验证环境变量设置正确

**端口冲突：**
- 检查端口 80、8080 或 3306 是否已被占用
- 修改 docker-compose.yml 中的端口映射

**卷权限问题：**
- 在 Linux 上，确保卷挂载的权限正确
- 使用命名卷而非绑定挂载

更多故障排查信息，请参阅 [docs/troubleshooting.md](docs/troubleshooting.md)。

## 贡献

我们欢迎贡献！请阅读我们的[贡献指南](CONTRIBUTING.md)获取详细信息：

- 开发工作流和分支策略
- 提交消息约定（Conventional Commits）
- Pull Request 流程
- 代码审查指南
- 测试要求

### 贡献者快速入门

1. Fork 仓库
2. 从 `develop` 创建功能分支：
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

3. 进行更改并使用约定式提交：
   ```bash
   git commit -m "feat(backend): add new feature"
   ```

4. 为新功能编写测试
5. 确保所有测试通过：
   ```bash
   cd backend
   mvn clean test verify
   ```

6. 推送并创建到 `develop` 的 Pull Request

### 分支保护

此仓库对 `main` 和 `develop` 分支使用分支保护规则：

- 所有更改需要 Pull Request
- 至少需要 1 个批准
- 所有 CI 检查必须通过
- 不允许直接推送

详情请参阅[分支保护指南](.github/BRANCH_PROTECTION.md)。

### 提交消息格式

我们遵循[约定式提交](https://www.conventionalcommits.org/)格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型**：`feat`、`fix`、`docs`、`style`、`refactor`、`test`、`chore`、`ci`、`build`、`perf`

**示例**：
```bash
feat(backend): add product search endpoint
fix(frontend): correct price display formatting
docs(readme): update deployment instructions
test(backend): add property tests for product CRUD
```

完整指南请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

本项目用于教育和演示目的。

## 文档

### 核心文档
- [架构文档](docs/architecture.md) - 系统架构、组件和设计决策
- [部署指南](docs/deployment.md) - 所有环境的分步部署说明
- [Dockerfile 优化](docs/dockerfile-optimizations.md) - 多阶段构建策略和优化技术
- [故障排查指南](docs/troubleshooting.md) - 常见问题和解决方案
- [API 文档](docs/api.md) - 完整的 REST API 参考和 OpenAPI 规范

### Kubernetes 文档（中文）
- [Kubernetes 部署指南](k8s/README_CN.md) - 综合部署说明
- [快速入门指南](k8s/QUICK_START_CN.md) - 常见任务快速参考
- [部署检查清单](k8s/DEPLOYMENT_CHECKLIST_CN.md) - 分步部署检查清单
- [实施总结](k8s/IMPLEMENTATION_SUMMARY_CN.md) - 完整实施概述

### 其他文档
- [CI/CD 设置指南](docs/CI_CD_SETUP.md) - 详细的 CI/CD 流水线配置
- [Docker Compose 设置](DOCKER_COMPOSE_SETUP.md) - Docker Compose 编排详情
- [CI/CD README](CI_CD_README.md) - CI/CD 流水线概述

## 联系方式

如有问题或疑问，请在仓库中提交 issue。

---

## 语言版本

- [English Version](README.md) - 英文版本
- [中文版本](README_CN.md) - 本文件
