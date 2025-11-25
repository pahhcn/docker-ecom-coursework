# MySQL Database Service Dockerfile
# Base image: MySQL 8.0
FROM mysql:8.0

# Set environment variables for MySQL configuration
ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_DATABASE=ecommerce
ENV MYSQL_USER=ecommerce_user
ENV MYSQL_PASSWORD=ecommerce_pass

# Configure MySQL for UTF-8 and timezone
# Create custom configuration file
RUN echo "[mysqld]" > /etc/mysql/conf.d/custom.cnf && \
    echo "character-set-server=utf8mb4" >> /etc/mysql/conf.d/custom.cnf && \
    echo "collation-server=utf8mb4_unicode_ci" >> /etc/mysql/conf.d/custom.cnf && \
    echo "default-time-zone='+00:00'" >> /etc/mysql/conf.d/custom.cnf && \
    echo "max_connections=100" >> /etc/mysql/conf.d/custom.cnf && \
    echo "connect_timeout=30" >> /etc/mysql/conf.d/custom.cnf && \
    echo "" >> /etc/mysql/conf.d/custom.cnf && \
    echo "[client]" >> /etc/mysql/conf.d/custom.cnf && \
    echo "default-character-set=utf8mb4" >> /etc/mysql/conf.d/custom.cnf

# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/

# Expose MySQL port
EXPOSE 3306

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} || exit 1

# Use default MySQL entrypoint
# The init.sql script will be automatically executed on first startup
