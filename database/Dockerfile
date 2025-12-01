# MySQL数据库服务Dockerfile
# 基础镜像：MySQL 8.0
FROM mysql:8.0

# 设置MySQL配置的环境变量
ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_DATABASE=ecommerce
ENV MYSQL_USER=ecommerce_user
ENV MYSQL_PASSWORD=ecommerce_pass

# 配置MySQL为UTF-8和时区
# 创建自定义配置文件
RUN echo "[mysqld]" > /etc/mysql/conf.d/custom.cnf && \
    echo "character-set-server=utf8mb4" >> /etc/mysql/conf.d/custom.cnf && \
    echo "collation-server=utf8mb4_unicode_ci" >> /etc/mysql/conf.d/custom.cnf && \
    echo "default-time-zone='+00:00'" >> /etc/mysql/conf.d/custom.cnf && \
    echo "max_connections=100" >> /etc/mysql/conf.d/custom.cnf && \
    echo "connect_timeout=30" >> /etc/mysql/conf.d/custom.cnf && \
    echo "" >> /etc/mysql/conf.d/custom.cnf && \
    echo "[client]" >> /etc/mysql/conf.d/custom.cnf && \
    echo "default-character-set=utf8mb4" >> /etc/mysql/conf.d/custom.cnf

# 复制初始化脚本
COPY init.sql /docker-entrypoint-initdb.d/

# 暴露MySQL端口
EXPOSE 3306

# 健康检查
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} || exit 1

# 使用默认的MySQL入口点
# init.sql脚本会在首次启动时自动执行
