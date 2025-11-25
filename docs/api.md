# API 文档

## 目录
1. [概述](#概述)
2. [基础 URL](#基础-url)
3. [认证](#认证)
4. [端点](#端点)
5. [数据模型](#数据模型)
6. [错误处理](#错误处理)
7. [示例](#示例)
8. [OpenAPI 规范](#openapi-规范)

## 概述

电商后端 API 提供用于管理产品数据的 RESTful 端点。API 遵循 REST 原则并返回 JSON 响应。

### API 版本
- **版本**：1.0.0
- **协议**：HTTP/HTTPS
- **格式**：JSON

### 功能
- 产品的完整 CRUD 操作
- 输入验证
- 带有描述性消息的错误处理
- 健康检查端点

## 基础 URL

### 开发环境
```
http://localhost:8080
```

### 生产环境
```
https://api.yourdomain.com
```

### API 前缀
所有产品端点都以 `/api` 为前缀

## 认证

**当前版本**：无需认证

**未来版本**：将实现基于 JWT 的认证

## 端点

### 健康检查

#### GET /actuator/health

检查 API 是否正在运行且健康。

**响应**：
```json
{
  "status": "UP"
}
```

**状态码**：
- `200 OK`：服务健康
- `503 Service Unavailable`：服务不健康

---

### 产品

#### GET /api/products

检索所有产品。

**请求**：
```http
GET /api/products HTTP/1.1
Host: localhost:8080
Accept: application/json
```

**响应**：
```json
[
  {
    "id": 1,
    "name": "笔记本电脑",
    "description": "高性能笔记本电脑",
    "price": 999.99,
    "stockQuantity": 50,
    "category": "电子产品",
    "imageUrl": "https://example.com/laptop.jpg",
    "createdAt": "2025-11-24T10:00:00",
    "updatedAt": "2025-11-24T10:00:00"
  },
  {
    "id": 2,
    "name": "鼠标",
    "description": "无线鼠标",
    "price": 29.99,
    "stockQuantity": 200,
    "category": "电子产品",
    "imageUrl": "https://example.com/mouse.jpg",
    "createdAt": "2025-11-24T10:00:00",
    "updatedAt": "2025-11-24T10:00:00"
  }
]
```

**状态码**：
- `200 OK`：成功
- `500 Internal Server Error`：服务器错误

---

#### GET /api/products/{id}

根据 ID 检索特定产品。

**参数**：
- `id`（路径，必需）：产品 ID（整数）

**请求**：
```http
GET /api/products/1 HTTP/1.1
Host: localhost:8080
Accept: application/json
```

**响应**：
```json
{
  "id": 1,
  "name": "笔记本电脑",
  "description": "高性能笔记本电脑",
  "price": 999.99,
  "stockQuantity": 50,
  "category": "电子产品",
  "imageUrl": "https://example.com/laptop.jpg",
  "createdAt": "2025-11-24T10:00:00",
  "updatedAt": "2025-11-24T10:00:00"
}
```

**状态码**：
- `200 OK`：成功
- `404 Not Found`：未找到产品
- `400 Bad Request`：无效的 ID 格式

**错误响应**（404）：
```json
{
  "timestamp": "2025-11-24T10:00:00",
  "status": 404,
  "error": "Not Found",
  "message": "Product not found with id: 1",
  "path": "/api/products/1"
}
```

---

#### POST /api/products

创建新产品。

**请求**：
```http
POST /api/products HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Accept: application/json

{
  "name": "键盘",
  "description": "机械键盘",
  "price": 79.99,
  "stockQuantity": 100,
  "category": "电子产品",
  "imageUrl": "https://example.com/keyboard.jpg"
}
```

**请求体**：
- `name`（字符串，必需）：产品名称（最多 255 个字符）
- `description`（字符串，可选）：产品描述
- `price`（数字，必需）：产品价格（必须 >= 0）
- `stockQuantity`（整数，必需）：库存数量（必须 >= 0）
- `category`（字符串，可选）：产品类别（最多 100 个字符）
- `imageUrl`（字符串，可选）：产品图片 URL（最多 500 个字符）

**响应**：
```json
{
  "id": 3,
  "name": "键盘",
  "description": "机械键盘",
  "price": 79.99,
  "stockQuantity": 100,
  "category": "电子产品",
  "imageUrl": "https://example.com/keyboard.jpg",
  "createdAt": "2025-11-24T10:00:00",
  "updatedAt": "2025-11-24T10:00:00"
}
```

**状态码**：
- `201 Created`：产品创建成功
- `400 Bad Request`：无效的输入数据
- `500 Internal Server Error`：服务器错误

**错误响应**（400）：
```json
{
  "timestamp": "2025-11-24T10:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed: name must not be blank",
  "path": "/api/products"
}
```

---

#### PUT /api/products/{id}

更新现有产品。

**参数**：
- `id`（路径，必需）：产品 ID（整数）

**请求**：
```http
PUT /api/products/1 HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Accept: application/json

{
  "name": "更新的笔记本电脑",
  "description": "更新的描述",
  "price": 1099.99,
  "stockQuantity": 45,
  "category": "电子产品",
  "imageUrl": "https://example.com/laptop-new.jpg"
}
```

**请求体**：与 POST 相同（所有字段必需）

**响应**：
```json
{
  "id": 1,
  "name": "更新的笔记本电脑",
  "description": "更新的描述",
  "price": 1099.99,
  "stockQuantity": 45,
  "category": "电子产品",
  "imageUrl": "https://example.com/laptop-new.jpg",
  "createdAt": "2025-11-24T10:00:00",
  "updatedAt": "2025-11-24T11:00:00"
}
```

**状态码**：
- `200 OK`：产品更新成功
- `404 Not Found`：未找到产品
- `400 Bad Request`：无效的输入数据
- `500 Internal Server Error`：服务器错误

---

#### DELETE /api/products/{id}

删除产品。

**参数**：
- `id`（路径，必需）：产品 ID（整数）

**请求**：
```http
DELETE /api/products/1 HTTP/1.1
Host: localhost:8080
```

**响应**：无内容

**状态码**：
- `204 No Content`：产品删除成功
- `404 Not Found`：未找到产品
- `400 Bad Request`：无效的 ID 格式

**错误响应**（404）：
```json
{
  "timestamp": "2025-11-24T10:00:00",
  "status": 404,
  "error": "Not Found",
  "message": "Product not found with id: 1",
  "path": "/api/products/1"
}
```

## 数据模型

### 产品

表示电商系统中的产品。

**字段**：

| 字段 | 类型 | 必需 | 约束 | 描述 |
|------|------|------|------|------|
| id | 整数 | 自动生成 | 唯一，主键 | 产品标识符 |
| name | 字符串 | 是 | 最多 255 字符，不能为空 | 产品名称 |
| description | 字符串 | 否 | 文本 | 产品描述 |
| price | 小数 | 是 | >= 0，2 位小数 | 产品价格 |
| stockQuantity | 整数 | 是 | >= 0 | 可用库存 |
| category | 字符串 | 否 | 最多 100 字符 | 产品类别 |
| imageUrl | 字符串 | 否 | 最多 500 字符，有效 URL | 产品图片 URL |
| createdAt | 日期时间 | 自动生成 | ISO 8601 格式 | 创建时间戳 |
| updatedAt | 日期时间 | 自动更新 | ISO 8601 格式 | 最后更新时间戳 |

**示例**：
```json
{
  "id": 1,
  "name": "笔记本电脑",
  "description": "配备 16GB 内存的高性能笔记本电脑",
  "price": 999.99,
  "stockQuantity": 50,
  "category": "电子产品",
  "imageUrl": "https://example.com/images/laptop.jpg",
  "createdAt": "2025-11-24T10:00:00",
  "updatedAt": "2025-11-24T10:00:00"
}
```

### 错误响应

标准错误响应格式。

**字段**：

| 字段 | 类型 | 描述 |
|------|------|------|
| timestamp | 日期时间 | 错误发生时间 |
| status | 整数 | HTTP 状态码 |
| error | 字符串 | HTTP 状态文本 |
| message | 字符串 | 详细错误消息 |
| path | 字符串 | 导致错误的请求路径 |

**示例**：
```json
{
  "timestamp": "2025-11-24T10:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed: price must be greater than or equal to 0",
  "path": "/api/products"
}
```

## 错误处理

### HTTP 状态码

| 代码 | 含义 | 使用场景 |
|------|------|----------|
| 200 | OK | 成功的 GET、PUT |
| 201 | Created | 成功的 POST |
| 204 | No Content | 成功的 DELETE |
| 400 | Bad Request | 无效输入，验证失败 |
| 404 | Not Found | 未找到资源 |
| 500 | Internal Server Error | 服务器错误 |
| 503 | Service Unavailable | 服务不健康 |

### 验证错误

**常见验证错误**：

1. **缺少必需字段**：
```json
{
  "message": "Validation failed: name must not be blank"
}
```

2. **无效价格**：
```json
{
  "message": "Validation failed: price must be greater than or equal to 0"
}
```

3. **无效库存数量**：
```json
{
  "message": "Validation failed: stockQuantity must be greater than or equal to 0"
}
```

4. **字段过长**：
```json
{
  "message": "Validation failed: name size must be between 0 and 255"
}
```

### 数据库错误

**连接错误**：
```json
{
  "timestamp": "2025-11-24T10:00:00",
  "status": 500,
  "error": "Internal Server Error",
  "message": "Database connection failed",
  "path": "/api/products"
}
```

## 示例

### cURL 示例

#### 获取所有产品
```bash
curl -X GET http://localhost:8080/api/products \
  -H "Accept: application/json"
```

#### 根据 ID 获取产品
```bash
curl -X GET http://localhost:8080/api/products/1 \
  -H "Accept: application/json"
```

#### 创建产品
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "键盘",
    "description": "机械键盘",
    "price": 79.99,
    "stockQuantity": 100,
    "category": "电子产品",
    "imageUrl": "https://example.com/keyboard.jpg"
  }'
```

#### 更新产品
```bash
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "更新的笔记本电脑",
    "description": "更新的描述",
    "price": 1099.99,
    "stockQuantity": 45,
    "category": "电子产品",
    "imageUrl": "https://example.com/laptop-new.jpg"
  }'
```

#### 删除产品
```bash
curl -X DELETE http://localhost:8080/api/products/1
```

#### 检查健康状态
```bash
curl -X GET http://localhost:8080/actuator/health
```

### JavaScript 示例

#### 使用 Fetch API

```javascript
// 获取所有产品
fetch('http://localhost:8080/api/products')
  .then(response => response.json())
  .then(products => console.log(products))
  .catch(error => console.error('错误:', error));

// 创建产品
fetch('http://localhost:8080/api/products', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: '键盘',
    description: '机械键盘',
    price: 79.99,
    stockQuantity: 100,
    category: '电子产品',
    imageUrl: 'https://example.com/keyboard.jpg'
  })
})
  .then(response => response.json())
  .then(product => console.log('已创建:', product))
  .catch(error => console.error('错误:', error));

// 更新产品
fetch('http://localhost:8080/api/products/1', {
  method: 'PUT',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: '更新的笔记本电脑',
    description: '更新的描述',
    price: 1099.99,
    stockQuantity: 45,
    category: '电子产品',
    imageUrl: 'https://example.com/laptop-new.jpg'
  })
})
  .then(response => response.json())
  .then(product => console.log('已更新:', product))
  .catch(error => console.error('错误:', error));

// 删除产品
fetch('http://localhost:8080/api/products/1', {
  method: 'DELETE'
})
  .then(response => {
    if (response.ok) {
      console.log('删除成功');
    }
  })
  .catch(error => console.error('错误:', error));
```

### Python 示例

#### 使用 Requests 库

```python
import requests

BASE_URL = 'http://localhost:8080/api'

# 获取所有产品
response = requests.get(f'{BASE_URL}/products')
products = response.json()
print(products)

# 根据 ID 获取产品
response = requests.get(f'{BASE_URL}/products/1')
product = response.json()
print(product)

# 创建产品
new_product = {
    'name': '键盘',
    'description': '机械键盘',
    'price': 79.99,
    'stockQuantity': 100,
    'category': '电子产品',
    'imageUrl': 'https://example.com/keyboard.jpg'
}
response = requests.post(f'{BASE_URL}/products', json=new_product)
created_product = response.json()
print(f'已创建: {created_product}')

# 更新产品
updated_product = {
    'name': '更新的笔记本电脑',
    'description': '更新的描述',
    'price': 1099.99,
    'stockQuantity': 45,
    'category': '电子产品',
    'imageUrl': 'https://example.com/laptop-new.jpg'
}
response = requests.put(f'{BASE_URL}/products/1', json=updated_product)
product = response.json()
print(f'已更新: {product}')

# 删除产品
response = requests.delete(f'{BASE_URL}/products/1')
if response.status_code == 204:
    print('删除成功')
```

## OpenAPI 规范

完整的 OpenAPI 3.0 规范请参见英文版文档。

## 测试 API

### 使用 Swagger UI

1. 将 Swagger 依赖添加到 `pom.xml`：
```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.2.0</version>
</dependency>
```

2. 访问 Swagger UI：
```
http://localhost:8080/swagger-ui.html
```

### 使用 Postman

1. 导入 OpenAPI 规范
2. 为每个端点创建请求
3. 使用不同的输入进行测试
4. 保存为集合以供重用

## 速率限制

**当前版本**：无速率限制

**未来版本**：将实现速率限制
- 每个 IP 每分钟 100 个请求
- 超过时返回 429 Too Many Requests 响应

## 版本控制

**当前版本**：v1（隐式）

**未来版本**：将使用 URL 版本控制
- `/api/v1/products`
- `/api/v2/products`

## 支持

如有 API 问题或疑问：
1. 查看本文档
2. 查看错误消息
3. 查看[故障排查指南](troubleshooting_CN.md)
4. 联系后端团队

## 参考资料

- [OpenAPI 规范](https://swagger.io/specification/)
- [REST API 最佳实践](https://restfulapi.net/)
- [HTTP 状态码](https://httpstatuses.com/)
- [Spring Boot REST 文档](https://spring.io/guides/gs/rest-service/)
