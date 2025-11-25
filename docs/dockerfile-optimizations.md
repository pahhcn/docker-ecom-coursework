# Dockerfile 优化指南

## 目录
1. [概述](#概述)
2. [多阶段构建](#多阶段构建)
3. [镜像大小优化](#镜像大小优化)
4. [构建缓存优化](#构建缓存优化)
5. [安全优化](#安全优化)
6. [性能优化](#性能优化)
7. [最佳实践](#最佳实践)

## 概述

本指南详细介绍了本项目中使用的 Dockerfile 优化技术,包括多阶段构建、层缓存、镜像大小优化和安全加固。

### 优化目标

- **更小的镜像大小**:减少存储和传输成本
- **更快的构建时间**:提高开发效率
- **更高的安全性**:减少攻击面
- **更好的缓存利用**:加速重复构建

## 多阶段构建

### 什么是多阶段构建?

多阶段构建允许在一个 Dockerfile 中使用多个 FROM 语句,每个阶段可以使用不同的基础镜像。这样可以将构建工具与运行时环境分离。

### 后端多阶段构建示例

```dockerfile
# ============ 阶段 1: 构建阶段 ============
FROM eclipse-temurin:17-jdk-alpine AS builder

# 设置工作目录
WORKDIR /app

# 只复制依赖文件(利用 Docker 层缓存)
COPY pom.xml .
COPY src ./src

# 下载依赖并构建应用
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests

# ============ 阶段 2: 运行时阶段 ============
FROM eclipse-temurin:17-jre-alpine

# 创建非 root 用户
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 设置工作目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /app/target/*.jar app.jar

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 8080

# 启动应用
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 优势

**镜像大小减少**:
- 构建阶段镜像:~600MB(JDK + Maven + 源代码)
- 最终运行时镜像:~180MB(仅 JRE + JAR)
- **节省 70% 空间**

**安全性提升**:
- 最终镜像不包含编译器和构建工具
- 减少潜在的安全漏洞
- 更小的攻击面

**构建效率**:
- 依赖项与源代码分层
- 利用 Docker 层缓存
- 仅在依赖更改时重新下载

### 前端多阶段构建示例

```dockerfile
# ============ 阶段 1: 构建阶段 ============
FROM node:18-alpine AS builder

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm ci --production

# 复制源代码
COPY . .

# 构建应用(如果需要)
RUN npm run build

# ============ 阶段 2: 运行时阶段 ============
FROM nginx:alpine

# 复制自定义 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 从构建阶段复制静态文件
COPY --from=builder /app/html /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
```

## 镜像大小优化

### 选择正确的基础镜像

**使用 Alpine 镜像**:

```dockerfile
# 不推荐: 完整 Ubuntu 镜像 (~200MB)
FROM ubuntu:22.04

# 推荐: Alpine 镜像 (~5MB)
FROM alpine:3.18
```

**镜像大小对比**:

| 基础镜像 | 大小 | 用例 |
|----------|------|------|
| `ubuntu:22.04` | ~77MB | 需要完整 GNU 工具链 |
| `debian:bullseye-slim` | ~80MB | 需要更多兼容性 |
| `alpine:3.18` | ~7MB | 生产环境,最小化 |
| `eclipse-temurin:17-jre-alpine` | ~180MB | Java 运行时 |
| `nginx:alpine` | ~40MB | Web 服务器 |

### 最小化层数

**不推荐**:每个命令创建一层
```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y vim
RUN apt-get clean
```

**推荐**:合并命令减少层数
```dockerfile
RUN apt-get update && \
    apt-get install -y curl vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### 移除不必要的文件

**清理包管理器缓存**:
```dockerfile
# Alpine
RUN apk add --no-cache package-name

# Debian/Ubuntu
RUN apt-get update && \
    apt-get install -y package-name && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**移除临时文件**:
```dockerfile
RUN wget https://example.com/file.tar.gz && \
    tar -xzf file.tar.gz && \
    rm file.tar.gz
```

### 使用 .dockerignore

创建 `.dockerignore` 文件排除不必要的文件:

```
# 版本控制
.git
.gitignore

# IDE 文件
.idea
.vscode
*.swp
*.swo

# 构建产物
target/
build/
dist/
node_modules/

# 测试和文档
*.md
tests/
docs/

# 日志和临时文件
*.log
tmp/
```

### 镜像大小对比

**优化前**:
```dockerfile
FROM maven:3.9-jdk-17
WORKDIR /app
COPY . .
RUN mvn clean package
EXPOSE 8080
CMD ["java", "-jar", "target/app.jar"]
```
**镜像大小**: ~800MB

**优化后**:
```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```
**镜像大小**: ~180MB
**节省**: 77.5%

## 构建缓存优化

### 层缓存原理

Docker 使用层缓存来加速构建:
- 每个指令创建一个层
- 如果指令和文件内容未更改,Docker 重用缓存层
- 一旦有层失效,后续所有层都需要重建

### 优化层顺序

**不推荐**:频繁更改的内容放在前面
```dockerfile
# 源代码经常更改
COPY src ./src
# 依赖很少更改,但每次都需要重新安装
COPY pom.xml .
RUN mvn dependency:go-offline
```

**推荐**:将不常更改的内容放在前面
```dockerfile
# 依赖文件很少更改
COPY pom.xml .
RUN mvn dependency:go-offline

# 源代码经常更改
COPY src ./src
RUN mvn package -DskipTests
```

### 分离依赖安装

**Node.js 示例**:
```dockerfile
# 先复制 package.json
COPY package*.json ./

# 安装依赖(可缓存)
RUN npm ci --production

# 再复制源代码(经常更改)
COPY . .
```

**Java/Maven 示例**:
```dockerfile
# 先复制 pom.xml
COPY pom.xml .

# 下载依赖(可缓存)
RUN mvn dependency:go-offline

# 再复制源代码(经常更改)
COPY src ./src
RUN mvn package -DskipTests
```

### 使用构建缓存挂载

**BuildKit 缓存挂载**:
```dockerfile
# 启用 BuildKit
# export DOCKER_BUILDKIT=1

RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests

RUN --mount=type=cache,target=/root/.npm \
    npm ci --production
```

### 缓存优化效果

**初次构建**:
- 无缓存:5-10 分钟
- 所有依赖需要下载

**后续构建(仅代码更改)**:
- 有缓存:30 秒 - 1 分钟
- 依赖从缓存加载
- **速度提升 90%**

## 安全优化

### 使用非 root 用户

**不推荐**:以 root 用户运行
```dockerfile
FROM nginx:alpine
COPY html /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]
```

**推荐**:创建并使用非 root 用户
```dockerfile
FROM nginx:alpine

# 创建非 root 用户
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 复制文件
COPY html /usr/share/nginx/html

# 更改所有权
RUN chown -R appuser:appgroup /usr/share/nginx/html

# 切换用户
USER appuser

CMD ["nginx", "-g", "daemon off;"]
```

### 扫描镜像漏洞

**使用 Trivy**:
```bash
# 安装 Trivy
brew install trivy

# 扫描镜像
trivy image ecommerce-backend:latest

# 仅显示高危和严重漏洞
trivy image --severity HIGH,CRITICAL ecommerce-backend:latest
```

**使用 Docker Scout**:
```bash
# 启用 Docker Scout
docker scout quickview ecommerce-backend:latest

# 查看 CVE 详情
docker scout cves ecommerce-backend:latest
```

### 最小化已安装包

**仅安装必需的包**:
```dockerfile
# 不推荐:安装完整工具集
RUN apk add --no-cache \
    bash curl wget vim git build-base

# 推荐:仅安装运行时需要的包
RUN apk add --no-cache \
    ca-certificates
```

### 固定版本号

**不推荐**:使用 latest 标签
```dockerfile
FROM node:latest
FROM ubuntu:latest
```

**推荐**:使用特定版本
```dockerfile
FROM node:18.17-alpine3.18
FROM ubuntu:22.04
```

### 使用 HTTPS 下载

**不推荐**:使用 HTTP
```dockerfile
RUN wget http://example.com/file.tar.gz
```

**推荐**:使用 HTTPS
```dockerfile
RUN wget https://example.com/file.tar.gz && \
    echo "checksum file.tar.gz" | sha256sum -c -
```

## 性能优化

### 优化 JVM 配置

**内存配置**:
```dockerfile
# 设置 JVM 内存限制
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

# 或使用容器感知配置
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### 优化应用启动

**使用 Spring Boot 层缓存**:
```dockerfile
# 提取应用层
RUN java -Djarmode=layertools -jar app.jar extract

# 按层复制(依赖很少更改)
COPY --from=builder app/dependencies/ ./
COPY --from=builder app/spring-boot-loader/ ./
COPY --from=builder app/snapshot-dependencies/ ./
COPY --from=builder app/application/ ./

CMD ["java", "org.springframework.boot.loader.JarLauncher"]
```

### 并行构建

**Docker Compose 并行构建**:
```bash
# 并行构建所有服务
docker compose build --parallel

# 设置并行度
docker compose build --parallel --parallel 3
```

### 使用 BuildKit

**启用 BuildKit**:
```bash
# 临时启用
export DOCKER_BUILDKIT=1
docker build .

# 永久启用
# 编辑 /etc/docker/daemon.json
{
  "features": {
    "buildkit": true
  }
}
```

**BuildKit 优势**:
- 并行构建步骤
- 更好的缓存管理
- 构建缓存导入/导出
- 更详细的构建输出

## 最佳实践

### 1. 使用明确的基础镜像标签

```dockerfile
# 不推荐
FROM node:latest

# 推荐
FROM node:18.17-alpine3.18
```

### 2. 合并 RUN 指令

```dockerfile
# 不推荐
RUN apk update
RUN apk add curl
RUN rm -rf /var/cache/apk/*

# 推荐
RUN apk update && \
    apk add --no-cache curl && \
    rm -rf /var/cache/apk/*
```

### 3. 利用构建参数

```dockerfile
ARG APP_VERSION=1.0.0
ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
```

### 4. 使用健康检查

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1
```

### 5. 优化 COPY 指令

```dockerfile
# 不推荐:复制整个目录
COPY . .

# 推荐:仅复制需要的文件
COPY src ./src
COPY pom.xml .
```

### 6. 使用多架构镜像

```bash
# 构建多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ecommerce-backend:latest \
  --push .
```

### 7. 添加元数据

```dockerfile
LABEL maintainer="your-email@example.com"
LABEL version="1.0.0"
LABEL description="E-commerce backend service"
LABEL org.opencontainers.image.source="https://github.com/your-org/repo"
```

### 8. 使用 ENTRYPOINT 和 CMD

```dockerfile
# ENTRYPOINT 定义不可变部分
ENTRYPOINT ["java", "-jar"]

# CMD 定义可覆盖部分
CMD ["app.jar"]

# 使用时可以覆盖 CMD
# docker run image-name app-v2.jar
```

## 优化检查清单

### 镜像大小
- [ ] 使用 Alpine 或 slim 基础镜像
- [ ] 使用多阶段构建
- [ ] 清理包管理器缓存
- [ ] 移除构建工具和依赖
- [ ] 使用 .dockerignore

### 构建速度
- [ ] 优化层顺序(依赖在前,代码在后)
- [ ] 使用构建缓存挂载
- [ ] 启用 BuildKit
- [ ] 并行构建多个服务
- [ ] 缓存依赖下载

### 安全性
- [ ] 使用非 root 用户运行
- [ ] 扫描镜像漏洞
- [ ] 固定基础镜像版本
- [ ] 最小化已安装包
- [ ] 使用 HTTPS 下载文件

### 可维护性
- [ ] 添加有意义的标签
- [ ] 使用环境变量配置
- [ ] 添加健康检查
- [ ] 文档化构建参数
- [ ] 版本化镜像

## 实际优化案例

### 案例 1: 后端服务优化

**优化前**:
```dockerfile
FROM maven:3.9-jdk-17
WORKDIR /app
COPY . .
RUN mvn clean package
EXPOSE 8080
CMD ["java", "-jar", "target/ecommerce-0.0.1-SNAPSHOT.jar"]
```
- 镜像大小: 850MB
- 构建时间: 5 分钟
- 安全问题: 以 root 运行,包含构建工具

**优化后**:
```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
RUN chown appuser:appgroup app.jar
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```
- 镜像大小: 185MB (节省 78%)
- 构建时间: 30 秒(缓存) / 2 分钟(无缓存)
- 安全: 非 root 用户,仅 JRE

### 案例 2: 前端服务优化

**优化前**:
```dockerfile
FROM nginx:latest
COPY html /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
```
- 镜像大小: 142MB
- 无健康检查

**优化后**:
```dockerfile
FROM nginx:1.25-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY html /usr/share/nginx/html
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1
USER nginx
CMD ["nginx", "-g", "daemon off;"]
```
- 镜像大小: 42MB (节省 70%)
- 包含健康检查
- 以非 root 用户运行

## 监控和分析

### 分析镜像大小

```bash
# 查看镜像大小
docker images ecommerce-backend

# 查看镜像层
docker history ecommerce-backend:latest

# 详细分析
docker history --no-trunc ecommerce-backend:latest
```

### 使用 dive 分析

```bash
# 安装 dive
brew install dive

# 分析镜像
dive ecommerce-backend:latest
```

### 构建时间分析

```bash
# 使用 BuildKit 详细输出
export DOCKER_BUILDKIT=1
docker build --progress=plain .

# 计时构建
time docker build -t ecommerce-backend:latest ./backend
```

## 其他资源

- [Docker 最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile 参考](https://docs.docker.com/engine/reference/builder/)
- [多阶段构建](https://docs.docker.com/build/building/multi-stage/)
- [BuildKit](https://docs.docker.com/build/buildkit/)
- [镜像安全最佳实践](https://docs.docker.com/engine/security/)
