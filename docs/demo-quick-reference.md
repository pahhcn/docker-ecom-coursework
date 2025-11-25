# Demo Quick Reference Guide
# 演示快速参考指南

## Quick Commands / 快速命令

### Setup / 设置
```bash
# Full demo setup (recommended) / 完整演示设置（推荐）
./scripts/demo-setup.sh

# Manual setup / 手动设置
docker-compose up --build -d
./scripts/seed-demo-data.sh
```

### Access Points / 访问点
- **Frontend / 前端**: http://localhost
- **Backend API / 后端API**: http://localhost:8080/api/products
- **Health Check / 健康检查**: http://localhost:8080/actuator/health
- **Grafana / 监控** (if enabled): http://localhost:3000 (admin/admin)

### CRUD Examples / CRUD示例

#### Create Product / 创建产品
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo Product",
    "description": "Created during demo",
    "price": 99.99,
    "stockQuantity": 50,
    "category": "Demo"
  }'
```

#### Get All Products / 获取所有产品
```bash
curl http://localhost:8080/api/products
```

#### Get Single Product / 获取单个产品
```bash
curl http://localhost:8080/api/products/1
```

#### Update Product / 更新产品
```bash
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Product",
    "description": "Modified during demo",
    "price": 149.99,
    "stockQuantity": 75,
    "category": "Demo"
  }'
```

#### Delete Product / 删除产品
```bash
curl -X DELETE http://localhost:8080/api/products/1
```

### Container Management / 容器管理

```bash
# View running containers / 查看运行中的容器
docker-compose ps

# View logs / 查看日志
docker-compose logs -f

# View specific service logs / 查看特定服务日志
docker-compose logs -f backend

# Restart service / 重启服务
docker-compose restart backend

# Stop all services / 停止所有服务
docker-compose down

# Stop and remove volumes / 停止并删除卷
docker-compose down -v
```

### Testing / 测试

```bash
# Run all tests / 运行所有测试
cd backend && mvn test

# Run specific test / 运行特定测试
mvn test -Dtest=ProductServiceTest

# Run with coverage / 运行并生成覆盖率
mvn test jacoco:report
```

### Monitoring / 监控

```bash
# Start monitoring stack / 启动监控栈
docker-compose -f docker-compose.monitoring.yml up -d

# Stop monitoring stack / 停止监控栈
docker-compose -f docker-compose.monitoring.yml down

# View Prometheus targets / 查看Prometheus目标
open http://localhost:9090/targets
```

### Kubernetes (Advanced) / Kubernetes（高级）

```bash
# Deploy to Kubernetes / 部署到Kubernetes
kubectl apply -f k8s/

# Check deployment / 检查部署
kubectl get pods -n ecommerce
kubectl get services -n ecommerce

# Blue-Green deployment / 蓝绿部署
cd k8s/blue-green
./deploy-blue-green.sh
./switch-traffic.sh green
```

## Demo Talking Points / 演示要点

### 1. Architecture / 架构
- Three-tier containerized application / 三层容器化应用
- Custom Docker network for service communication / 自定义Docker网络用于服务通信
- Volume persistence for database / 数据库卷持久化
- Multi-stage builds for optimization / 多阶段构建优化

### 2. Docker Features / Docker功能
- **Multi-stage builds** / **多阶段构建**: Separate build and runtime environments
- **Health checks** / **健康检查**: Automatic service health monitoring
- **Networks** / **网络**: Custom bridge network for isolation
- **Volumes** / **卷**: Persistent data storage
- **Resource limits** / **资源限制**: CPU and memory constraints

### 3. Development Workflow / 开发工作流
- **Local development** / **本地开发**: Docker Compose for easy setup
- **Testing** / **测试**: Unit, integration, and property-based tests
- **CI/CD** / **CI/CD**: Automated build, test, and deploy
- **Monitoring** / **监控**: Real-time metrics and alerts

### 4. Best Practices / 最佳实践
- **Image optimization** / **镜像优化**: Small image sizes (<200MB for backend)
- **Security** / **安全**: Non-root users, no hardcoded secrets
- **Documentation** / **文档**: Comprehensive docs in English and Chinese
- **Testing** / **测试**: 80%+ code coverage with multiple test types

## Common Demo Scenarios / 常见演示场景

### Scenario 1: Full System Deployment / 场景1：完整系统部署
1. Run demo setup script / 运行演示设置脚本
2. Show containers starting in order / 显示容器按顺序启动
3. Verify health checks / 验证健康检查
4. Access frontend / 访问前端

### Scenario 2: CRUD Operations / 场景2：CRUD操作
1. Show product list in frontend / 在前端显示产品列表
2. Create new product via API / 通过API创建新产品
3. Verify it appears in frontend / 验证它出现在前端
4. Update the product / 更新产品
5. Delete the product / 删除产品

### Scenario 3: Data Persistence / 场景3：数据持久化
1. Show current products / 显示当前产品
2. Restart database container / 重启数据库容器
3. Verify data still exists / 验证数据仍然存在

### Scenario 4: Testing / 场景4：测试
1. Show test structure / 显示测试结构
2. Run unit tests / 运行单元测试
3. Run property-based tests / 运行基于属性的测试
4. Show test coverage report / 显示测试覆盖率报告

### Scenario 5: CI/CD Pipeline / 场景5：CI/CD流水线
1. Show pipeline configuration / 显示流水线配置
2. Explain stages / 解释阶段
3. Show recent pipeline execution / 显示最近的流水线执行
4. Highlight automated testing / 强调自动化测试

### Scenario 6: Monitoring / 场景6：监控
1. Start monitoring stack / 启动监控栈
2. Open Grafana dashboard / 打开Grafana仪表板
3. Show key metrics / 显示关键指标
4. Generate load and observe / 生成负载并观察

## Troubleshooting During Demo / 演示期间故障排除

### Issue: Service won't start / 问题：服务无法启动
```bash
# Check logs / 检查日志
docker-compose logs <service>

# Restart service / 重启服务
docker-compose restart <service>
```

### Issue: Port already in use / 问题：端口已被占用
```bash
# Find process / 查找进程
lsof -i :8080

# Kill process / 终止进程
kill -9 <PID>
```

### Issue: Can't connect to API / 问题：无法连接到API
```bash
# Check backend health / 检查后端健康
curl http://localhost:8080/actuator/health

# Check network / 检查网络
docker network inspect ecommerce-network
```

### Issue: No demo data / 问题：没有演示数据
```bash
# Re-seed data / 重新填充数据
./scripts/seed-demo-data.sh
```

## Time Management / 时间管理

### 5-Minute Demo / 5分钟演示
1. Introduction (30s) / 介绍（30秒）
2. Architecture overview (30s) / 架构概览（30秒）
3. Deploy system (60s) / 部署系统（60秒）
4. Show frontend (30s) / 显示前端（30秒）
5. CRUD demo (90s) / CRUD演示（90秒）
6. Testing (30s) / 测试（30秒）
7. Conclusion (30s) / 结论（30秒）

### 8-Minute Demo / 8分钟演示
1. Introduction (30s) / 介绍（30秒）
2. Architecture overview (45s) / 架构概览（45秒）
3. Deploy system (90s) / 部署系统（90秒）
4. Frontend demo (60s) / 前端演示（60秒）
5. CRUD operations (90s) / CRUD操作（90秒）
6. Data persistence (30s) / 数据持久化（30秒）
7. CI/CD pipeline (60s) / CI/CD流水线（60秒）
8. Testing (45s) / 测试（45秒）
9. Monitoring (optional, 45s) / 监控（可选，45秒）
10. Documentation (30s) / 文档（30秒）
11. Conclusion (30s) / 结论（30秒）

## Key Metrics to Highlight / 要强调的关键指标

- **Image sizes** / **镜像大小**: Backend <200MB, Frontend <50MB
- **Test coverage** / **测试覆盖率**: 80%+
- **Property tests** / **属性测试**: 100+ iterations each
- **Services** / **服务**: 3 containerized services
- **Deployment time** / **部署时间**: <2 minutes
- **Health checks** / **健康检查**: Automatic monitoring
- **Documentation** / **文档**: Bilingual (EN/CN)

## Post-Demo Cleanup / 演示后清理

```bash
# Stop all services / 停止所有服务
docker-compose down

# Stop monitoring / 停止监控
docker-compose -f docker-compose.monitoring.yml down

# Remove volumes (optional) / 删除卷（可选）
docker-compose down -v

# Clean up system / 清理系统
docker system prune -f
```

## Resources / 资源

- **Full demo script** / **完整演示脚本**: `docs/demo-script.md`
- **Chinese documentation** / **中文文档**: `docs/README_CN.md`
- **Architecture docs** / **架构文档**: `docs/architecture.md`
- **Deployment guide** / **部署指南**: `docs/deployment.md`
- **Troubleshooting** / **故障排除**: `docs/troubleshooting.md`

---

**Good luck with your demo! / 祝您演示顺利！** 🎬
