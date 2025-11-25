# Demo Checklist / 演示检查清单

## Pre-Recording / 录制前

### Environment Setup / 环境设置
- [ ] Docker Desktop is running / Docker Desktop正在运行
- [ ] All previous containers stopped / 所有之前的容器已停止
- [ ] Ports 80, 8080, 3306 are available / 端口80、8080、3306可用
- [ ] Git repository is clean / Git仓库是干净的
- [ ] Internet connection is stable / 网络连接稳定

### System Preparation / 系统准备
- [ ] Close unnecessary applications / 关闭不必要的应用
- [ ] Disable notifications / 禁用通知
- [ ] Clear terminal history / 清除终端历史
- [ ] Set terminal font size to 16-18pt / 设置终端字体大小为16-18pt
- [ ] Prepare browser (close tabs, clear cache) / 准备浏览器（关闭标签页，清除缓存）

### Documentation Ready / 文档准备
- [ ] `docs/demo-script.md` reviewed / 已查看演示脚本
- [ ] `docs/demo-quick-reference.md` open / 打开快速参考
- [ ] Code examples prepared / 准备代码示例
- [ ] Architecture diagram ready / 架构图准备就绪

### Recording Tools / 录制工具
- [ ] Screen recording software tested / 屏幕录制软件已测试
- [ ] Microphone tested / 麦克风已测试
- [ ] Audio levels checked / 音频级别已检查
- [ ] Recording area set correctly / 录制区域设置正确


## During Recording / 录制期间

### Introduction (30s) / 介绍（30秒）
- [ ] Introduce yourself / 自我介绍
- [ ] State project purpose / 说明项目目的
- [ ] Mention key technologies / 提及关键技术
- [ ] Show README / 显示README

### Architecture (45s) / 架构（45秒）
- [ ] Open architecture diagram / 打开架构图
- [ ] Explain three-tier structure / 解释三层结构
- [ ] Mention Docker networking / 提及Docker网络
- [ ] Show docker-compose.yml / 显示docker-compose.yml

### Deployment (90s) / 部署（90秒）
- [ ] Run `./scripts/demo-setup.sh` / 运行演示设置脚本
- [ ] Show build process / 显示构建过程
- [ ] Show services starting / 显示服务启动
- [ ] Show health checks passing / 显示健康检查通过
- [ ] Run `docker-compose ps` / 运行容器状态命令
- [ ] Show volumes and networks / 显示卷和网络

### Frontend Demo (60s) / 前端演示（60秒）
- [ ] Open http://localhost in browser / 在浏览器中打开前端
- [ ] Show product list page / 显示产品列表页面
- [ ] Click on a product / 点击产品
- [ ] Show product details / 显示产品详情
- [ ] Demonstrate responsive design / 演示响应式设计

### CRUD Operations (90s) / CRUD操作（90秒）
- [ ] Create: POST new product / 创建：POST新产品
- [ ] Show product in frontend / 在前端显示产品
- [ ] Read: GET all products / 读取：GET所有产品
- [ ] Read: GET specific product / 读取：GET特定产品
- [ ] Update: PUT product / 更新：PUT产品
- [ ] Refresh frontend to show update / 刷新前端显示更新
- [ ] Delete: DELETE product / 删除：DELETE产品
- [ ] Verify deletion in frontend / 在前端验证删除

### Data Persistence (30s) / 数据持久化（30秒）
- [ ] Show current products / 显示当前产品
- [ ] Restart database: `docker-compose restart mysql` / 重启数据库
- [ ] Wait for health check / 等待健康检查
- [ ] Verify data still exists / 验证数据仍存在

### CI/CD Pipeline (60s) / CI/CD流水线（60秒）
- [ ] Open `.gitlab-ci.yml` or `Jenkinsfile` / 打开CI配置文件
- [ ] Explain pipeline stages / 解释流水线阶段
- [ ] Show build stage / 显示构建阶段
- [ ] Show test stage / 显示测试阶段
- [ ] Show deploy stage / 显示部署阶段
- [ ] Show CI/CD dashboard (if available) / 显示CI/CD仪表板

### Testing (45s) / 测试（45秒）
- [ ] Show test directory structure / 显示测试目录结构
- [ ] Run `mvn test` / 运行测试
- [ ] Show test output / 显示测试输出
- [ ] Mention unit tests / 提及单元测试
- [ ] Mention integration tests / 提及集成测试
- [ ] Mention property-based tests / 提及基于属性的测试
- [ ] Show coverage report / 显示覆盖率报告

### Monitoring (Optional, 45s) / 监控（可选，45秒）
- [ ] Start monitoring: `docker-compose -f docker-compose.monitoring.yml up -d`
- [ ] Open Grafana at http://localhost:3000
- [ ] Login (admin/admin) / 登录
- [ ] Show e-commerce dashboard / 显示电子商务仪表板
- [ ] Point out CPU/Memory metrics / 指出CPU/内存指标
- [ ] Point out request rate / 指出请求速率
- [ ] Point out response times / 指出响应时间

### Documentation (30s) / 文档（30秒）
- [ ] Show `docs/` directory / 显示文档目录
- [ ] Open `docs/architecture.md` / 打开架构文档
- [ ] Open `docs/README_CN.md` / 打开中文文档
- [ ] Mention API documentation / 提及API文档
- [ ] Mention troubleshooting guide / 提及故障排除指南

### Advanced Features (Optional, 30s) / 高级功能（可选，30秒）
- [ ] Show `k8s/` directory / 显示Kubernetes目录
- [ ] Show blue-green deployment scripts / 显示蓝绿部署脚本
- [ ] Explain deployment strategy / 解释部署策略
- [ ] Show monitoring setup / 显示监控设置

### Conclusion (30s) / 结论（30秒）
- [ ] Summarize key features / 总结关键功能
- [ ] Mention best practices / 提及最佳实践
- [ ] Show final system view / 显示最终系统视图
- [ ] Thank viewers / 感谢观众

## Post-Recording / 录制后

### Cleanup / 清理
- [ ] Stop all services: `docker-compose down` / 停止所有服务
- [ ] Stop monitoring: `docker-compose -f docker-compose.monitoring.yml down`
- [ ] Remove volumes (optional): `docker-compose down -v`
- [ ] Clean Docker system: `docker system prune -f`

### Video Editing / 视频编辑
- [ ] Review raw footage / 查看原始素材
- [ ] Cut unnecessary parts / 剪切不必要的部分
- [ ] Speed up long processes / 加快长时间过程
- [ ] Add text overlays for key points / 为关键点添加文字叠加
- [ ] Add intro/outro / 添加片头/片尾
- [ ] Add background music (optional) / 添加背景音乐（可选）
- [ ] Check audio levels / 检查音频级别
- [ ] Export in appropriate format / 以适当格式导出

### Quality Check / 质量检查
- [ ] Watch entire video / 观看整个视频
- [ ] Check audio quality / 检查音频质量
- [ ] Check video quality / 检查视频质量
- [ ] Verify all features shown / 验证显示的所有功能
- [ ] Check timing (5-8 minutes) / 检查时长（5-8分钟）

### Publishing / 发布
- [ ] Add title and description / 添加标题和描述
- [ ] Add tags / 添加标签
- [ ] Add thumbnail / 添加缩略图
- [ ] Upload to platform / 上传到平台
- [ ] Share link / 分享链接

## Emergency Procedures / 应急程序

### If Service Fails to Start / 如果服务启动失败
1. Check logs: `docker-compose logs <service>`
2. Restart service: `docker-compose restart <service>`
3. If still failing, explain issue and move on
4. 检查日志、重启服务、如果仍然失败则解释问题并继续

### If Port is Occupied / 如果端口被占用
1. Find process: `lsof -i :<port>`
2. Kill process: `kill -9 <PID>`
3. Restart services
4. 查找进程、终止进程、重启服务

### If Demo Data Missing / 如果演示数据丢失
1. Run: `./scripts/seed-demo-data.sh`
2. Verify: `curl http://localhost:8080/api/products`
3. 运行填充脚本、验证数据

### If Recording Fails / 如果录制失败
1. Save current state
2. Take a break
3. Review checklist
4. Start fresh recording
5. 保存当前状态、休息、查看检查清单、重新开始录制

## Tips for Success / 成功技巧

- **Practice first** / **先练习**: Do at least one complete dry run
- **Speak clearly** / **说话清晰**: Not too fast, pause between sections
- **Show, don't tell** / **展示，不要只说**: Let the system demonstrate itself
- **Be prepared** / **做好准备**: Have backup plans for common issues
- **Stay calm** / **保持冷静**: If something goes wrong, explain and continue
- **Time yourself** / **计时**: Keep track of time during recording
- **Engage viewers** / **吸引观众**: Explain why features matter
- **End strong** / **强势结束**: Summarize key achievements

## Notes / 笔记

Use this space for personal notes during practice runs:
在练习过程中使用此空间记录个人笔记：

---

**Good luck! / 祝好运！** 🎬
