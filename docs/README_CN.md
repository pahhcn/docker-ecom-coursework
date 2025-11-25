# Docker电子商务系统 - 完整文档

## 项目概述

这是一个完整的基于Docker的电子商务数据管理系统，展示了现代DevOps实践。系统由三个容器化服务组成：

1. **前端层**：基于Nginx的静态Web服务器，提供产品目录页面
2. **应用层**：Spring Boot REST API，提供产品管理的CRUD操作
3. **数据层**：MySQL数据库，提供持久化存储

整个系统使用Docker Compose进行本地开发编排，使用Kubernetes进行生产部署。完整的CI/CD流水线自动化构建、测试和部署过程。

## 技术栈

- **前端**：HTML5、CSS3、JavaScript、Nginx Alpine
- **后端**：Java 17、Spring Boot 3.x、Maven
- **数据库**：MySQL 8.0
- **容器化**：Docker、Docker Compose
- **编排**：Kubernetes（可选高级功能）
- **CI/CD**：Jenkins 或 GitLab CI
- **测试**：JUnit 5、Spring Boot Test、TestContainers、jqwik
- **监控**：Prometheus + Grafana（可选）

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                        主机                                   │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker自定义网络                           │ │
│  │                                                          │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌───────┐│ │
│  │  │   前端       │─────▶│   后端       │─────▶│ MySQL ││ │
│  │  │   (Nginx)    │      │(Spring Boot) │      │  数据库││ │
│  │  │   端口 80    │      │  端口 8080   │      │ 3306  ││ │
│  │  └──────────────┘      └──────────────┘      └───────┘│ │
│  │                                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker卷                                   │ │
│  │  - mysql-data（持久化数据库存储）                      │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Git

### 安装步骤

1. **克隆仓库**
```bash
git clone <repository-url>
cd dockerwork
```

2. **运行演示设置脚本**
```bash
./scripts/demo-setup.sh
```

这个脚本会：
- 清理现有容器和卷
- 构建所有Docker镜像
- 按正确顺序启动所有服务
- 填充演示数据
- 验证系统健康状况

3. **访问应用**
- 前端：http://localhost
- 后端API：http://localhost:8080/api/products
- 健康检查：http://localhost:8080/actuator/health

### 手动部署（可选）

如果您想手动部署而不使用脚本：

```bash
# 构建并启动所有服务
docker-compose up --build -d

# 查看日志
docker-compose logs -f

# 检查容器状态
docker-compose ps
```

## 核心功能

### 1. 前端服务

**功能**：
- 显示产品列表页面
- 显示产品详情页面
- 响应式设计
- 与后端API通信

**技术细节**：
- 基础镜像：`nginx:alpine`
- 暴露端口：80
- 健康检查：每30秒HTTP GET到 `/`

**文件结构**：
```
frontend/
├── Dockerfile          # 多阶段构建配置
├── nginx.conf          # Nginx配置，包含API代理
└── html/
    ├── index.html      # 产品列表页面
    ├── product-detail.html  # 产品详情页面
    ├── css/
    │   └── styles.css  # 样式表
    └── js/
        └── app.js      # JavaScript逻辑
```

### 2. 后端API服务

**功能**：
- 提供RESTful API端点
- 处理产品CRUD操作
- 数据验证
- 错误处理

**API端点**：

| 方法 | 端点 | 描述 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | /api/products | 获取所有产品 | - | 200 + Product[] |
| GET | /api/products/{id} | 根据ID获取产品 | - | 200 + Product |
| POST | /api/products | 创建新产品 | Product | 201 + Product |
| PUT | /api/products/{id} | 更新产品 | Product | 200 + Product |
| DELETE | /api/products/{id} | 删除产品 | - | 204 |

**技术细节**：
- 基础镜像：多阶段（构建用maven:3.9-eclipse-temurin-17，运行用eclipse-temurin:17-jre-alpine）
- 暴露端口：8080
- 健康检查：每30秒HTTP GET到 `/actuator/health`

**环境变量**：
- `DB_HOST`：数据库主机名（默认：mysql）
- `DB_PORT`：数据库端口（默认：3306）
- `DB_NAME`：数据库名称（默认：ecommerce）
- `DB_USER`：数据库用户名
- `DB_PASSWORD`：数据库密码

### 3. 数据库服务

**功能**：
- 持久化存储产品数据
- 自动初始化数据库架构
- 数据持久化跨容器重启

**数据库架构**：
```sql
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    category VARCHAR(100),
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**技术细节**：
- 基础镜像：`mysql:8.0`
- 暴露端口：3306
- 卷挂载：`mysql-data:/var/lib/mysql`
- 字符集：UTF-8（utf8mb4）

## Docker配置详解

### Dockerfile优化

#### 前端Dockerfile
```dockerfile
# 多阶段构建
FROM nginx:alpine

# 复制静态文件
COPY html/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80
```

**优化技术**：
- 使用Alpine基础镜像（小体积）
- 单层复制操作
- 内置健康检查

#### 后端Dockerfile
```dockerfile
# 构建阶段
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**优化技术**：
- 多阶段构建（分离构建和运行环境）
- 依赖缓存（先复制pom.xml）
- 使用JRE而非JDK（减小镜像大小）
- 最终镜像大小 < 200MB

### Docker Compose配置

**网络配置**：
- 自定义桥接网络：`ecommerce-network`
- 所有服务连接到此网络
- 服务使用服务名作为主机名通信

**服务依赖**：
```
frontend → backend → database
```

**健康检查策略**：
- 数据库：在后端启动前检查MySQL ping
- 后端：在前端启动前检查 `/actuator/health`
- 前端：检查Nginx响应

**资源限制**：
- 前端：256MB内存，0.5 CPU
- 后端：512MB内存，1.0 CPU
- 数据库：1GB内存，1.0 CPU

## CRUD操作示例

### 创建产品（Create）

```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "新产品",
    "description": "产品描述",
    "price": 99.99,
    "stockQuantity": 100,
    "category": "电子产品",
    "imageUrl": "https://example.com/image.jpg"
  }'
```

**响应**：
```json
{
  "id": 1,
  "name": "新产品",
  "description": "产品描述",
  "price": 99.99,
  "stockQuantity": 100,
  "category": "电子产品",
  "imageUrl": "https://example.com/image.jpg",
  "createdAt": "2025-11-25T10:00:00",
  "updatedAt": "2025-11-25T10:00:00"
}
```

### 读取产品（Read）

```bash
# 获取所有产品
curl http://localhost:8080/api/products

# 获取特定产品
curl http://localhost:8080/api/products/1
```

### 更新产品（Update）

```bash
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "更新的产品",
    "description": "更新的描述",
    "price": 149.99,
    "stockQuantity": 75,
    "category": "电子产品",
    "imageUrl": "https://example.com/new-image.jpg"
  }'
```

### 删除产品（Delete）

```bash
curl -X DELETE http://localhost:8080/api/products/1
```

## 测试策略

### 单元测试

**框架**：JUnit 5 + Mockito + Spring Boot Test

**覆盖范围**：
- 服务层方法测试
- 验证逻辑测试
- 错误处理测试
- 目标覆盖率：80%+

**运行测试**：
```bash
cd backend
mvn test
```

### 集成测试

**框架**：Spring Boot Test + TestContainers

**测试场景**：
- 完整API工作流测试（创建→读取→更新→删除）
- 前端-后端通信测试
- 后端-数据库通信测试
- Docker Compose编排测试

### 基于属性的测试

**框架**：jqwik（Java属性测试库）

**配置**：
- 每个属性测试运行最少100次迭代
- 使用自定义生成器生成Product域对象
- 每个测试标记对应的设计属性编号

**测试属性**：
1. **产品检索完整性**：对于任何存储在数据库中的产品集，GET请求应返回所有产品
2. **产品创建持久化**：对于任何有效的产品数据，创建后应可检索
3. **产品更新正确性**：对于任何现有产品和更新数据，更新应正确修改数据
4. **产品删除完整性**：对于任何现有产品，删除后应不再可检索
5. **卷持久化**：对于任何产品集，容器重启后数据应保持完整
6. **端到端数据流完整性**：从前端到数据库的数据应保持一致

## CI/CD流水线

### GitLab CI配置

**阶段**：
1. **构建**：构建所有Docker镜像
2. **测试**：运行单元测试和集成测试
3. **推送**：推送镜像到容器仓库
4. **部署**：部署到目标环境

**文件**：`.gitlab-ci.yml`

### Jenkins配置

**流水线阶段**：
1. **源代码**：从Git拉取代码
2. **构建**：构建Docker镜像
3. **测试**：运行测试套件
4. **推送**：推送到Docker Hub
5. **部署**：部署到环境

**文件**：`Jenkinsfile`

### 自动化测试

**测试报告**：
- JUnit XML报告用于CI集成
- 代码覆盖率报告（JaCoCo）
- 测试执行时间跟踪
- 失败测试通知

## 监控（可选）

### Prometheus + Grafana

**启动监控栈**：
```bash
docker-compose -f docker-compose.monitoring.yml up -d
```

**访问点**：
- Grafana：http://localhost:3000（admin/admin）
- Prometheus：http://localhost:9090

**监控指标**：
- 容器CPU/内存使用
- 请求速率和响应时间
- 数据库连接池状态
- JVM堆使用和垃圾回收

**仪表板**：
- 系统概览仪表板
- 服务特定仪表板
- 数据库性能仪表板

## Kubernetes部署（高级）

### 部署到Kubernetes

```bash
# 创建命名空间
kubectl create namespace ecommerce

# 应用配置
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/database/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/frontend/

# 检查部署
kubectl get pods -n ecommerce
kubectl get services -n ecommerce
```

### 蓝绿部署

**策略**：
1. 部署新版本与旧版本并行运行
2. 在隔离环境中测试新版本
3. 原子性地将流量从旧版本切换到新版本
4. 保持旧版本运行以便快速回滚

**执行部署**：
```bash
cd k8s/blue-green
./deploy-blue-green.sh
```

**切换流量**：
```bash
./switch-traffic.sh green
```

**回滚**：
```bash
./rollback.sh
```

## 常用命令

### Docker Compose命令

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend

# 停止所有服务
docker-compose down

# 停止并删除卷
docker-compose down -v

# 重启特定服务
docker-compose restart backend

# 查看容器状态
docker-compose ps

# 进入容器
docker-compose exec backend bash
```

### Docker命令

```bash
# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 查看镜像
docker images

# 删除未使用的资源
docker system prune -f

# 查看容器日志
docker logs <container-id>

# 进入容器
docker exec -it <container-id> bash

# 查看容器资源使用
docker stats
```

### 数据库命令

```bash
# 连接到MySQL
docker-compose exec mysql mysql -u root -p

# 备份数据库
docker exec mysql mysqldump -u root -p ecommerce > backup.sql

# 恢复数据库
docker exec -i mysql mysql -u root -p ecommerce < backup.sql

# 查看数据库
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"
```

## 故障排除

### 常见问题

#### 1. 容器无法启动

**症状**：容器立即退出或无法启动

**解决方案**：
```bash
# 查看日志
docker-compose logs <service-name>

# 检查容器状态
docker-compose ps

# 重新构建镜像
docker-compose build --no-cache <service-name>
```

#### 2. 服务无法通信

**症状**：前端无法连接到后端，或后端无法连接到数据库

**解决方案**：
```bash
# 检查网络
docker network ls
docker network inspect ecommerce-network

# 验证服务名解析
docker-compose exec frontend ping backend
docker-compose exec backend ping mysql

# 检查端口
docker-compose ps
```

#### 3. 数据库连接失败

**症状**：后端无法连接到数据库

**解决方案**：
```bash
# 检查数据库是否运行
docker-compose ps mysql

# 检查数据库日志
docker-compose logs mysql

# 验证数据库健康
docker-compose exec mysql mysqladmin ping -h localhost

# 检查环境变量
docker-compose exec backend env | grep DB_
```

#### 4. 端口冲突

**症状**：无法绑定端口

**解决方案**：
```bash
# 查找占用端口的进程
lsof -i :8080
lsof -i :3306

# 终止进程
kill -9 <PID>

# 或修改docker-compose.yml中的端口映射
```

#### 5. 卷权限问题

**症状**：无法写入卷

**解决方案**：
```bash
# 检查卷
docker volume ls
docker volume inspect mysql-data

# 删除并重新创建卷
docker-compose down -v
docker-compose up -d
```

### 性能问题

#### 1. 容器运行缓慢

**诊断**：
```bash
# 检查资源使用
docker stats

# 检查日志中的错误
docker-compose logs
```

**解决方案**：
- 增加资源限制
- 优化应用代码
- 检查数据库查询性能

#### 2. 镜像构建缓慢

**解决方案**：
- 使用.dockerignore排除不必要的文件
- 优化Dockerfile层顺序
- 使用构建缓存
- 使用多阶段构建

## 安全最佳实践

### 1. 镜像安全

- 使用官方基础镜像
- 定期更新基础镜像
- 扫描镜像漏洞
- 使用最小化镜像（Alpine）

### 2. 运行时安全

- 以非root用户运行容器
- 使用只读根文件系统
- 删除不必要的Linux能力
- 实施资源限制

### 3. 网络安全

- 使用自定义网络隔离服务
- 仅暴露必要端口
- 使用TLS/SSL（生产环境）

### 4. 密钥管理

- 使用环境变量或Docker secrets
- 不要在镜像中硬编码密钥
- 定期轮换密钥
- 使用外部密钥管理（生产环境）

## 维护和运维

### 备份策略

**数据库备份**：
```bash
# 每日自动备份
docker exec mysql mysqldump -u root -p ecommerce > backup-$(date +%Y%m%d).sql

# 保留30天
find . -name "backup-*.sql" -mtime +30 -delete
```

### 日志管理

**日志策略**：
- 所有容器日志到stdout/stderr
- 使用Docker日志驱动
- 集中日志聚合（ELK栈）
- 日志轮转防止磁盘空间问题

### 更新流程

**滚动更新**：
1. 构建新镜像并打版本标签
2. 推送到仓库
3. 更新docker-compose.yml或K8s清单
4. 使用零停机策略部署
5. 验证新版本健康
6. 完成部署

## 项目结构

```
dockerwork/
├── .github/                    # GitHub Actions工作流
├── .gitlab-ci.yml             # GitLab CI配置
├── Jenkinsfile                # Jenkins流水线配置
├── docker-compose.yml         # Docker Compose配置
├── docker-compose.monitoring.yml  # 监控栈配置
├── README.md                  # 英文文档
├── docs/                      # 文档目录
│   ├── README_CN.md          # 中文文档（本文件）
│   ├── demo-script.md        # 演示脚本
│   ├── architecture.md       # 架构文档
│   ├── deployment.md         # 部署指南
│   ├── troubleshooting.md    # 故障排除指南
│   └── ...
├── scripts/                   # 脚本目录
│   └── demo-setup.sh         # 演示设置脚本
├── frontend/                  # 前端服务
│   ├── Dockerfile
│   ├── nginx.conf
│   └── html/
├── backend/                   # 后端服务
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── database/                  # 数据库配置
│   ├── Dockerfile
│   └── init.sql
├── k8s/                       # Kubernetes清单
│   ├── frontend/
│   ├── backend/
│   ├── database/
│   └── blue-green/           # 蓝绿部署
└── monitoring/                # 监控配置
    ├── prometheus/
    ├── grafana/
    └── alertmanager/
```

## 学习资源

### Docker
- [Docker官方文档](https://docs.docker.com/)
- [Docker Compose文档](https://docs.docker.com/compose/)
- [Dockerfile最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

### Kubernetes
- [Kubernetes官方文档](https://kubernetes.io/docs/)
- [Kubernetes中文文档](https://kubernetes.io/zh-cn/docs/)

### Spring Boot
- [Spring Boot官方文档](https://spring.io/projects/spring-boot)
- [Spring Boot中文文档](https://springdoc.cn/spring-boot/)

### 测试
- [JUnit 5文档](https://junit.org/junit5/docs/current/user-guide/)
- [jqwik文档](https://jqwik.net/docs/current/user-guide.html)
- [TestContainers文档](https://www.testcontainers.org/)

## 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork仓库
2. 创建特性分支（`git checkout -b feature/AmazingFeature`）
3. 提交更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 开启Pull Request

### 提交消息格式

使用约定式提交：

```
<类型>(<范围>): <主题>

<正文>

<页脚>
```

**类型**：
- `feat`：新功能
- `fix`：错误修复
- `docs`：文档更改
- `style`：代码风格更改
- `refactor`：代码重构
- `test`：测试添加或更改
- `chore`：构建过程或工具更改

## 许可证

本项目采用MIT许可证 - 详见LICENSE文件

## 联系方式

如有问题或建议，请：
- 开启Issue
- 提交Pull Request
- 发送邮件至：[your-email@example.com]

## 致谢

感谢所有为这个项目做出贡献的人！

---

**祝您使用愉快！** 🚀
