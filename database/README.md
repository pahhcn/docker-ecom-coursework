# 数据库服务

电商系统的 MySQL 8.0 数据库服务。

## 配置

- **字符集**: UTF-8 (utf8mb4)
- **排序规则**: utf8mb4_unicode_ci
- **时区**: UTC
- **最大连接数**: 100
- **连接超时**: 30 秒

## 模式

### Products 表

| 列 | 类型 | 描述 |
|--------|------|-------------|
| id | BIGINT | 主键,自动递增 |
| name | VARCHAR(255) | 产品名称 (必需) |
| description | TEXT | 产品描述 |
| price | DECIMAL(10,2) | 产品价格 (必需) |
| stock_quantity | INT | 可用库存 (默认: 0) |
| category | VARCHAR(100) | 产品类别 |
| image_url | VARCHAR(500) | 产品图片 URL |
| created_at | TIMESTAMP | 创建时间戳 |
| updated_at | TIMESTAMP | 最后更新时间戳 |

### 索引

- `idx_category`: category 列的索引,用于更快的过滤
- `idx_name`: name 列的索引,用于更快的搜索

## 初始化

`init.sql` 脚本:
1. 使用 UTF-8 编码创建 `ecommerce` 数据库
2. 使用适当的模式创建 `products` 表
3. 为测试填充 8 个示例产品

## 构建和运行

### 使用 Docker

```bash
# 构建镜像
docker build -t ecommerce-mysql ./database

# 运行容器
docker run -d \
  --name ecommerce-db \
  -p 3306:3306 \
  -v mysql-data:/var/lib/mysql \
  ecommerce-mysql
```

### 使用 Docker Compose

数据库服务在 `docker-compose.yml` 中配置,将与其他服务一起自动启动。

## 环境变量

- `MYSQL_ROOT_PASSWORD`: Root 用户密码
- `MYSQL_DATABASE`: 数据库名称 (默认: ecommerce)
- `MYSQL_USER`: 应用用户
- `MYSQL_PASSWORD`: 应用用户密码

## 健康检查

容器包含健康检查,每 10 秒 ping 一次 MySQL 以确保服务正常运行。

## 数据持久化

数据使用挂载在 `/var/lib/mysql` 的 Docker 卷持久化。这确保数据在容器重启和删除后仍然保留。

## 连接到数据库

### 从后端服务

后端服务使用环境变量连接:
- 主机: `mysql` (Docker 网络中的服务名称)
- 端口: `3306`
- 数据库: `ecommerce`
- 用户: `ecommerce_user`
- 密码: `ecommerce_pass`

### 直接连接 (开发)

```bash
# 使用 MySQL 客户端
mysql -h localhost -P 3306 -u ecommerce_user -p

# 使用 Docker exec
docker exec -it ecommerce-db mysql -u ecommerce_user -p
```

## 备份和恢复

### 备份

```bash
docker exec ecommerce-db mysqldump -u root -p ecommerce > backup.sql
```

### 恢复

```bash
docker exec -i ecommerce-db mysql -u root -p ecommerce < backup.sql
```

## 故障排查

### 连接被拒绝

- 确保容器正在运行: `docker ps`
- 检查健康状态: `docker inspect ecommerce-db`
- 验证端口映射: `docker port ecommerce-db`

### 初始化脚本未运行

- 初始化脚本仅在首次启动空数据目录时运行
- 要重新运行: 删除卷并重启容器

### 字符编码问题

- 验证配置: `docker exec ecommerce-db mysql -u root -p -e "SHOW VARIABLES LIKE 'char%';"`
- 应该为所有字符集变量显示 `utf8mb4`
