# 电商后端服务

## Docker 构建

### 多阶段构建策略

此 Dockerfile 使用多阶段构建方法来优化最终镜像大小:

**阶段 1: 构建阶段**
- 基础镜像: `maven:3.9-eclipse-temurin-17`
- 目的: 编译和打包 Spring Boot 应用
- 优化: 首先复制 `pom.xml` 以利用 Docker 层缓存来缓存依赖项

**阶段 2: 运行阶段**
- 基础镜像: `eclipse-temurin:17-jre-alpine`
- 目的: 以最小占用运行应用
- 大小: < 200MB (目标 < 500MB,符合要求)
- 安全性: 以非 root 用户运行

### 构建说明

```bash
# 构建 Docker 镜像
docker build -t ecommerce-backend:latest .

# 运行容器
docker run -p 8080:8080 \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_NAME=ecommerce \
  -e DB_USER=root \
  -e DB_PASSWORD=password \
  ecommerce-backend:latest
```

### 环境变量

| 变量 | 描述 | 默认值 |
|----------|-------------|---------|
| DB_HOST | 数据库主机名 | mysql |
| DB_PORT | 数据库端口 | 3306 |
| DB_NAME | 数据库名称 | ecommerce |
| DB_USER | 数据库用户名 | root |
| DB_PASSWORD | 数据库密码 | (必需) |
| SPRING_PROFILES_ACTIVE | 活动的 Spring 配置文件 | default |

### 健康检查

容器包含健康检查,用于验证应用是否正在运行:
- 端点: `http://localhost:8080/actuator/health`
- 间隔: 30 秒
- 超时: 3 秒
- 启动期间: 40 秒
- 重试次数: 3

### 镜像优化

Dockerfile 实施了几种优化:

1. **层缓存**: 依赖项在单独的层中下载,只有在 `pom.xml` 更改时才重新构建
2. **多阶段构建**: 最终镜像中不包含构建工件
3. **Alpine 基础镜像**: 使用 Alpine Linux 以获得最小镜像大小
4. **仅 JRE**: 运行阶段使用 JRE 而不是完整的 JDK
5. **非 root 用户**: 应用以非特权用户身份运行以提高安全性

### 预期镜像大小

- 构建阶段: ~800MB (不包含在最终镜像中)
- 运行阶段: ~180-200MB
- 总最终镜像: < 200MB (远低于 500MB 要求)
