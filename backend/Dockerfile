# Spring Boot后端多阶段Dockerfile
# 第一阶段：使用Maven进行构建
FROM maven:3.9-eclipse-temurin-17 AS build

# 设置工作目录
WORKDIR /app

# 首先复制pom.xml以利用Docker层缓存
# 只有pom.xml更改时才会重新下载依赖
COPY pom.xml .

# 下载依赖（这一层会被缓存）
RUN mvn dependency:go-offline -B

# 复制源代码
COPY src ./src

# 构建应用（跳过测试以加快构建速度）
RUN mvn clean package -DskipTests -B

# 第二阶段：使用轻量级JRE的运行时阶段
FROM eclipse-temurin:17-jre-alpine

# 设置工作目录
WORKDIR /app

# 创建非root用户以提高安全性
RUN addgroup -S spring && adduser -S spring -G spring

# 从构建阶段复制JAR文件
COPY --from=build /app/target/*.jar app.jar

# 更改文件所有权为非root用户
RUN chown spring:spring app.jar

# 切换到非root用户
USER spring:spring

# 暴露应用端口
EXPOSE 8080

# 配置健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# 为容器化环境设置JVM选项
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# 运行应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
