# Jenkins配置指南

## 自动配置完成 ✅

Jenkins Job已经自动创建并配置完成！

## 访问Jenkins

1. 打开浏览器访问: http://localhost:8090
2. 使用你之前创建的管理员账号登录

## 查看Pipeline任务

1. 在Jenkins首页，你会看到 `docker-ecom-coursework` 任务
2. 点击任务名称进入详情页
3. 点击 "立即构建" 开始第一次构建

## Job配置说明

- **Git仓库**: https://github.com/pahhcn/docker-ecom-coursework.git
- **分支**: develop
- **Jenkinsfile路径**: Jenkinsfile
- **自动触发**: 每5分钟检查代码变更

## Pipeline阶段

1. **代码检出** - 从GitHub拉取最新代码
2. **构建阶段** - 构建后端应用和Docker镜像
3. **单元测试** - 运行单元测试
4. **集成测试** - 运行属性测试
5. **代码覆盖率报告** - 生成JaCoCo覆盖率报告
6. **推送镜像到仓库** - 推送到本地registry
7. **部署服务** - 使用docker-compose部署
8. **健康检查** - 验证服务状态

## 查看构建结果

- **控制台输出**: 点击构建编号 → Console Output
- **测试报告**: 构建页面 → Test Result
- **覆盖率报告**: 构建页面 → JaCoCo Coverage Report

## 手动触发构建

```bash
# 方式1: Web界面点击"立即构建"

# 方式2: 使用curl触发
curl -X POST http://localhost:8090/job/docker-ecom-coursework/build
```

## 故障排查

### 构建失败
1. 检查控制台输出
2. 确认Docker服务正常运行
3. 确认宿主机路径 `/home/swe/docker-ecom-coursework` 正确

### Git拉取失败
1. 检查网络连接
2. 确认GitHub仓库可访问
3. 如果是私有仓库，需要配置Git凭据

### Docker命令失败
1. 确认Jenkins容器有Docker权限
2. 检查 `/var/run/docker.sock` 挂载正确
3. 查看Jenkins日志: `docker logs jenkins-local`

## 重新加载配置

如果修改了Job配置文件，重启Jenkins即可：

```bash
docker restart jenkins-local
```
