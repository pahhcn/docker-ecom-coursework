# Project Demonstration Script

## 项目演示脚本

**Duration**: 5-8 minutes  
**持续时间**: 5-8分钟

---

## Pre-Recording Checklist / 录制前检查清单

- [ ] Clean Docker environment (run cleanup script)
- [ ] 清理Docker环境（运行清理脚本）
- [ ] Close unnecessary applications
- [ ] 关闭不必要的应用程序
- [ ] Set browser zoom to 100%
- [ ] 将浏览器缩放设置为100%
- [ ] Prepare terminal with clear history
- [ ] 准备终端并清除历史记录
- [ ] Test microphone and screen recording
- [ ] 测试麦克风和屏幕录制

---

## Demo Flow / 演示流程

### 1. Introduction (30 seconds) / 介绍（30秒）

**Script**:
> "Hello! Today I'll demonstrate a complete Docker-based e-commerce system. This project showcases containerization, orchestration, CI/CD pipelines, and monitoring. Let's dive in!"

**中文脚本**:
> "大家好！今天我将演示一个完整的基于Docker的电子商务系统。这个项目展示了容器化、编排、CI/CD流水线和监控。让我们开始吧！"

**Show**:
- Project README on screen
- 在屏幕上显示项目README
- Quick overview of directory structure
- 快速浏览目录结构

---

### 2. Architecture Overview (45 seconds) / 架构概览（45秒）

**Script**:
> "The system consists of three containerized services: an Nginx frontend, a Spring Boot backend API, and a MySQL database. All services communicate through a custom Docker network."

**中文脚本**:
> "该系统由三个容器化服务组成：Nginx前端、Spring Boot后端API和MySQL数据库。所有服务通过自定义Docker网络进行通信。"

**Show**:
- Open `docs/architecture.md`
- 打开 `docs/architecture.md`
- Display architecture diagram
- 显示架构图
- Briefly show `docker-compose.yml`
- 简要显示 `docker-compose.yml`

---

### 3. Docker Compose Deployment (90 seconds) / Docker Compose部署（90秒）

**Script**:
> "Let's deploy the entire system with a single command. Watch as Docker Compose builds the images, creates the network, and starts all services in the correct order."

**中文脚本**:
> "让我们用一个命令部署整个系统。观察Docker Compose如何构建镜像、创建网络并按正确顺序启动所有服务。"

**Commands**:
```bash
# Show the demo setup script
cat scripts/demo-setup.sh

# Run the deployment
./scripts/demo-setup.sh

# Show running containers
docker ps

# Show networks
docker network ls

# Show volumes
docker volume ls
```

**Show**:
- Terminal output showing build process
- 终端输出显示构建过程
- Services starting in dependency order
- 服务按依赖顺序启动
- Health checks passing
- 健康检查通过

---

### 4. Frontend Demonstration (60 seconds) / 前端演示（60秒）

**Script**:
> "Now let's access the frontend. The application displays a product catalog with full CRUD capabilities."

**中文脚本**:
> "现在让我们访问前端。应用程序显示具有完整CRUD功能的产品目录。"

**Actions**:
1. Open browser to `http://localhost`
2. 在浏览器中打开 `http://localhost`
3. Show product list page
4. 显示产品列表页面
5. Click on a product to view details
6. 点击产品查看详情
7. Show responsive design (resize window)
8. 显示响应式设计（调整窗口大小）

**Highlight**:
- Clean, modern UI
- 简洁现代的UI
- Product images and information
- 产品图片和信息
- Navigation between pages
- 页面间导航

---

### 5. CRUD Operations (90 seconds) / CRUD操作（90秒）

**Script**:
> "Let's demonstrate all CRUD operations. I'll create a new product, update it, and then delete it."

**中文脚本**:
> "让我们演示所有CRUD操作。我将创建一个新产品、更新它，然后删除它。"

**Actions**:

#### Create / 创建
```bash
# Use the demo script to create a product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo Product",
    "description": "Created during demonstration",
    "price": 99.99,
    "stockQuantity": 50,
    "category": "Demo"
  }'
```

- Show the new product appears in frontend
- 显示新产品出现在前端

#### Read / 读取
```bash
# Get all products
curl http://localhost:8080/api/products

# Get specific product
curl http://localhost:8080/api/products/1
```

#### Update / 更新
```bash
# Update the product
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Demo Product",
    "description": "Modified during demonstration",
    "price": 149.99,
    "stockQuantity": 75,
    "category": "Demo"
  }'
```

- Refresh frontend to show updated data
- 刷新前端显示更新的数据

#### Delete / 删除
```bash
# Delete the product
curl -X DELETE http://localhost:8080/api/products/1
```

- Show product is removed from frontend
- 显示产品从前端移除

---

### 6. Data Persistence (30 seconds) / 数据持久化（30秒）

**Script**:
> "Let's verify data persistence. I'll restart the database container, and you'll see that all data remains intact."

**中文脚本**:
> "让我们验证数据持久化。我将重启数据库容器，您将看到所有数据保持完整。"

**Commands**:
```bash
# Restart database
docker-compose restart mysql

# Wait for health check
sleep 10

# Verify data still exists
curl http://localhost:8080/api/products
```

**Show**:
- Container restarting
- 容器重启
- Data still available after restart
- 重启后数据仍然可用

---

### 7. CI/CD Pipeline (60 seconds) / CI/CD流水线（60秒）

**Script**:
> "The project includes a complete CI/CD pipeline. Let me show you the pipeline configuration and a recent execution."

**中文脚本**:
> "该项目包含完整的CI/CD流水线。让我向您展示流水线配置和最近的执行情况。"

**Show**:

#### GitLab CI
- Open `.gitlab-ci.yml`
- 打开 `.gitlab-ci.yml`
- Explain stages: build, test, push, deploy
- 解释阶段：构建、测试、推送、部署
- Show GitLab CI/CD interface (if available)
- 显示GitLab CI/CD界面（如果可用）

#### Jenkins
- Open `Jenkinsfile`
- 打开 `Jenkinsfile`
- Show pipeline stages
- 显示流水线阶段
- Show Jenkins dashboard (if available)
- 显示Jenkins仪表板（如果可用）

**Highlight**:
- Automated testing
- 自动化测试
- Image building and pushing
- 镜像构建和推送
- Deployment automation
- 部署自动化

---

### 8. Testing & Code Quality (45 seconds) / 测试与代码质量（45秒）

**Script**:
> "The project includes comprehensive testing: unit tests, integration tests, and property-based tests. Let's run the test suite."

**中文脚本**:
> "该项目包含全面的测试：单元测试、集成测试和基于属性的测试。让我们运行测试套件。"

**Commands**:
```bash
# Run tests
cd backend
mvn test

# Show test results
cat target/surefire-reports/*.txt
```

**Show**:
- Test execution output
- 测试执行输出
- All tests passing
- 所有测试通过
- Coverage report (if available)
- 覆盖率报告（如果可用）

---

### 9. Monitoring (Optional - 45 seconds) / 监控（可选 - 45秒）

**Script**:
> "If monitoring is set up, we can observe system metrics in real-time using Prometheus and Grafana."

**中文脚本**:
> "如果设置了监控，我们可以使用Prometheus和Grafana实时观察系统指标。"

**Actions**:
```bash
# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Wait for services
sleep 15
```

**Show**:
- Open Grafana at `http://localhost:3000`
- 在 `http://localhost:3000` 打开Grafana
- Login (admin/admin)
- 登录（admin/admin）
- Show e-commerce dashboard
- 显示电子商务仪表板
- Point out key metrics:
- 指出关键指标：
  - Container CPU/Memory usage
  - 容器CPU/内存使用
  - Request rate
  - 请求速率
  - Response times
  - 响应时间
  - Database connections
  - 数据库连接

---

### 10. Documentation (30 seconds) / 文档（30秒）

**Script**:
> "The project includes comprehensive documentation covering architecture, deployment, troubleshooting, and more."

**中文脚本**:
> "该项目包含全面的文档，涵盖架构、部署、故障排除等内容。"

**Show**:
- Quick scroll through `docs/` directory
- 快速浏览 `docs/` 目录
- Open `docs/architecture.md`
- 打开 `docs/architecture.md`
- Open `docs/deployment.md`
- 打开 `docs/deployment.md`
- Show API documentation
- 显示API文档

---

### 11. Advanced Features (Optional - 30 seconds) / 高级功能（可选 - 30秒）

**Script**:
> "The project also includes advanced features like Kubernetes deployment and blue-green deployment strategies."

**中文脚本**:
> "该项目还包括高级功能，如Kubernetes部署和蓝绿部署策略。"

**Show**:
- `k8s/` directory structure
- `k8s/` 目录结构
- `k8s/blue-green/` deployment scripts
- `k8s/blue-green/` 部署脚本
- Briefly explain blue-green strategy
- 简要解释蓝绿策略

---

### 12. Conclusion (30 seconds) / 结论（30秒）

**Script**:
> "This project demonstrates a complete containerized application with Docker, including multi-stage builds, orchestration, CI/CD, testing, and monitoring. All code is well-documented and follows best practices. Thank you for watching!"

**中文脚本**:
> "这个项目展示了一个完整的Docker容器化应用，包括多阶段构建、编排、CI/CD、测试和监控。所有代码都有良好的文档并遵循最佳实践。感谢观看！"

**Show**:
- Final view of running system
- 运行系统的最终视图
- GitHub/GitLab repository (if public)
- GitHub/GitLab仓库（如果公开）

---

## Cleanup After Demo / 演示后清理

```bash
# Stop all services
docker-compose down

# Stop monitoring (if started)
docker-compose -f docker-compose.monitoring.yml down

# Optional: Remove volumes
docker-compose down -v
```

---

## Tips for Recording / 录制技巧

1. **Practice First** / **先练习**
   - Do a complete dry run before recording
   - 录制前进行完整的演练
   - Time each section
   - 为每个部分计时

2. **Terminal Setup** / **终端设置**
   - Use large font (16-18pt)
   - 使用大字体（16-18pt）
   - Clear background
   - 清晰的背景
   - Consider using `asciinema` for terminal recording
   - 考虑使用 `asciinema` 进行终端录制

3. **Browser Setup** / **浏览器设置**
   - Close unnecessary tabs
   - 关闭不必要的标签页
   - Disable notifications
   - 禁用通知
   - Use incognito mode for clean appearance
   - 使用隐身模式以获得干净的外观

4. **Pacing** / **节奏**
   - Speak clearly and not too fast
   - 说话清晰，不要太快
   - Pause briefly between sections
   - 在各部分之间短暂停顿
   - Allow time for viewers to read output
   - 给观众时间阅读输出

5. **Editing** / **编辑**
   - Speed up long build processes
   - 加快长时间的构建过程
   - Add text overlays for key points
   - 为关键点添加文字叠加
   - Include background music (optional)
   - 包含背景音乐（可选）

---

## Troubleshooting / 故障排除

### If services don't start / 如果服务无法启动
```bash
# Check logs
docker-compose logs

# Restart specific service
docker-compose restart backend
```

### If ports are in use / 如果端口被占用
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

### If demo data is missing / 如果演示数据丢失
```bash
# Re-run setup script
./scripts/demo-setup.sh
```

---

## Recording Tools Recommendations / 录制工具推荐

- **Screen Recording** / **屏幕录制**:
  - OBS Studio (Free, cross-platform)
  - Camtasia (Paid, professional)
  - QuickTime (Mac)
  - SimpleScreenRecorder (Linux)

- **Video Editing** / **视频编辑**:
  - DaVinci Resolve (Free)
  - Adobe Premiere Pro (Paid)
  - iMovie (Mac)
  - Kdenlive (Linux)

- **Terminal Recording** / **终端录制**:
  - asciinema (Terminal sessions)
  - Terminalizer (Animated GIFs)

---

Good luck with your demonstration! / 祝您演示顺利！
