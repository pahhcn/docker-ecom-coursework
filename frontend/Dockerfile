# 前端服务多阶段构建
# 第一阶段：构建阶段（为将来可能的构建步骤做准备）
FROM nginx:alpine AS builder

# 将静态文件复制到临时位置
COPY html /tmp/html

# 第二阶段：运行时阶段
FROM nginx:alpine

# 添加元数据标签
LABEL maintainer="ecommerce-team"
LABEL description="电商系统前端服务"
LABEL version="1.0"

# 删除默认的nginx配置
RUN rm /etc/nginx/nginx.conf

# 复制自定义nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 从构建阶段复制静态文件
COPY --from=builder /tmp/html /usr/share/nginx/html

# 创建简单的健康检查HTML页面
RUN echo "healthy" > /usr/share/nginx/html/health.html

# 暴露端口80
EXPOSE 80

# 健康检查配置
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/health || exit 1

# 前台运行nginx
CMD ["nginx", "-g", "daemon off;"]
