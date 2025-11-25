# CI/CD 检查清单

本检查清单用于验证 CI/CD 流水线的正确设置和部署准备情况。

## 目录
1. [流水线设置](#流水线设置)
2. [代码仓库配置](#代码仓库配置)
3. [构建阶段](#构建阶段)
4. [测试阶段](#测试阶段)
5. [推送阶段](#推送阶段)
6. [部署阶段](#部署阶段)
7. [监控和通知](#监控和通知)

## 流水线设置

### GitLab CI

- [ ] `.gitlab-ci.yml` 文件存在于仓库根目录
- [ ] GitLab Runner 已注册并正常运行
- [ ] Runner 已安装 Docker 执行器
- [ ] Runner 有足够的资源(CPU、内存)
- [ ] 流水线已在 GitLab UI 中启用

**验证步骤**:
```bash
# 检查 GitLab CI 文件语法
gitlab-ci-lint .gitlab-ci.yml

# 或使用 GitLab 在线工具
# Project → CI/CD → Pipelines → CI Lint
```

### Jenkins

- [ ] Jenkins 服务器运行正常(版本 2.400+)
- [ ] 已安装所需插件:
  - [ ] Docker Pipeline
  - [ ] JaCoCo
  - [ ] JUnit
  - [ ] HTML Publisher
  - [ ] Git
- [ ] `Jenkinsfile` 存在于仓库根目录
- [ ] Jenkins 流水线任务已创建
- [ ] Webhook 已配置(可选)

**验证步骤**:
```bash
# 验证 Jenkinsfile 语法
# Jenkins → Pipeline Syntax → Declarative Directive Generator

# 或使用 Jenkins CLI
java -jar jenkins-cli.jar declarative-linter < Jenkinsfile
```

### GitHub Actions

- [ ] `.github/workflows/ci-cd.yml` 文件存在
- [ ] GitHub Actions 已启用
  - Settings → Actions → General → Allow all actions
- [ ] 工作流权限已配置
  - Settings → Actions → General → Workflow permissions
- [ ] GitHub Container Registry 访问已配置

**验证步骤**:
```bash
# 检查工作流文件语法
# 使用 act 工具本地验证
act -l

# 或推送到仓库并查看 Actions 选项卡
```

## 代码仓库配置

### 分支设置

- [ ] 主分支:
  - [ ] `main` 分支存在
  - [ ] 分支保护已启用
  - [ ] 需要 PR 审查
  - [ ] 需要 CI 检查通过
- [ ] 开发分支:
  - [ ] `develop` 分支存在
  - [ ] 用于预发布部署

**验证步骤**:
```bash
# 查看分支
git branch -a

# 检查当前分支
git branch --show-current
```

### CI/CD 变量和秘密

#### GitLab

- [ ] CI/CD 变量已配置(Settings → CI/CD → Variables):
  - [ ] `CI_REGISTRY_USER`: 容器仓库用户名
  - [ ] `CI_REGISTRY_PASSWORD`: 容器仓库密码(受保护、屏蔽)
  - [ ] `CI_REGISTRY`: 仓库 URL
  - [ ] `SLACK_WEBHOOK_URL`: Slack 通知(可选)

**验证步骤**:
```bash
# 在流水线中打印变量(不包括密钥)
echo $CI_REGISTRY_USER
echo $CI_REGISTRY
```

#### Jenkins

- [ ] 凭证已添加(Manage Jenkins → Manage Credentials):
  - [ ] `docker-credentials-id`: Docker 仓库凭证
  - [ ] `docker-registry-url`: 仓库 URL
  - [ ] Git 仓库凭证(如需要)

**验证步骤**:
```groovy
// 在 Jenkinsfile 中测试
withCredentials([usernamePassword(credentialsId: 'docker-credentials-id', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
    echo "User: ${USER}"
}
```

#### GitHub Actions

- [ ] 仓库秘密已配置(Settings → Secrets and variables → Actions):
  - [ ] `GITHUB_TOKEN`: 自动提供
  - [ ] `SLACK_WEBHOOK_URL`: Slack 通知(可选)
  - [ ] 其他云服务凭证(如需要)

**验证步骤**:
```yaml
# 在工作流中引用秘密
- name: Test secret
  run: echo "Token length: ${#GITHUB_TOKEN}"
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 构建阶段

### Docker 镜像构建

- [ ] Dockerfile 存在:
  - [ ] `backend/Dockerfile`
  - [ ] `frontend/Dockerfile`
  - [ ] `database/Dockerfile` (如有自定义)
- [ ] `.dockerignore` 文件已配置
- [ ] 多阶段构建已实施
- [ ] 基础镜像版本已固定

**验证步骤**:
```bash
# 本地测试构建
docker build -t ecommerce-backend:test ./backend
docker build -t ecommerce-frontend:test ./frontend

# 检查镜像大小
docker images | grep ecommerce

# 验证镜像可运行
docker run --rm ecommerce-backend:test
```

### Maven 构建

- [ ] `pom.xml` 配置正确
- [ ] 所有依赖可下载
- [ ] 构建插件已配置:
  - [ ] maven-compiler-plugin
  - [ ] maven-surefire-plugin (测试)
  - [ ] jacoco-maven-plugin (覆盖率)

**验证步骤**:
```bash
# 本地构建
cd backend
mvn clean package -DskipTests

# 验证 JAR 文件
ls -lh target/*.jar
java -jar target/*.jar --version
```

### 构建缓存

- [ ] Docker BuildKit 已启用
- [ ] 构建缓存挂载已配置
- [ ] 层顺序已优化(依赖在前,代码在后)
- [ ] Maven 依赖缓存已配置

**验证步骤**:
```bash
# 测试缓存效果
time docker build -t test:1 ./backend
# 再次构建,应该更快
time docker build -t test:2 ./backend
```

## 测试阶段

### 单元测试

- [ ] 单元测试存在于 `src/test/java`
- [ ] 测试命名约定正确(`*Test.java`)
- [ ] 测试覆盖关键功能:
  - [ ] Service 层
  - [ ] Controller 层
  - [ ] Repository 层

**验证步骤**:
```bash
# 运行单元测试
cd backend
mvn test

# 检查测试报告
ls target/surefire-reports/
```

### 集成测试

- [ ] 集成测试已配置
- [ ] TestContainers 依赖已添加
- [ ] 测试使用真实数据库容器
- [ ] 测试命名约定正确(`*IntegrationTest.java`)

**验证步骤**:
```bash
# 运行集成测试
mvn verify

# 或仅运行集成测试
mvn test -Dtest=*IntegrationTest
```

### 基于属性的测试

- [ ] jqwik 依赖已添加
- [ ] 属性测试已编写(`*PropertyTest.java`)
- [ ] 测试迭代次数已配置(100+)
- [ ] 关键属性已验证:
  - [ ] 产品检索
  - [ ] 产品创建
  - [ ] 产品更新
  - [ ] 产品删除

**验证步骤**:
```bash
# 运行属性测试
mvn test -Dtest=*PropertyTest

# 查看报告
cat target/surefire-reports/*PropertyTest.txt
```

### 代码覆盖率

- [ ] JaCoCo 插件已配置
- [ ] 覆盖率阈值已设置(80%)
- [ ] 覆盖率报告生成
- [ ] 流水线在覆盖率不足时失败

**验证步骤**:
```bash
# 生成覆盖率报告
mvn clean test jacoco:report

# 查看报告
open target/site/jacoco/index.html

# 检查覆盖率
mvn jacoco:check
```

### 测试报告

- [ ] Surefire 报告生成
- [ ] JUnit XML 报告可用
- [ ] HTML 报告生成(可选)
- [ ] 流水线显示测试结果

**验证步骤**:
```bash
# 检查报告文件
ls target/surefire-reports/
ls target/site/jacoco/
```

## 推送阶段

### 容器仓库

- [ ] 仓库已创建:
  - [ ] ecommerce-frontend
  - [ ] ecommerce-backend
- [ ] 仓库访问权限已配置
- [ ] 推送凭证已验证
- [ ] 仓库 URL 已正确配置

**验证步骤**:
```bash
# 手动登录测试
docker login <registry-url> -u <username>

# 标记镜像
docker tag ecommerce-backend:latest <registry>/ecommerce-backend:test

# 推送测试
docker push <registry>/ecommerce-backend:test

# 拉取验证
docker pull <registry>/ecommerce-backend:test
```

### 镜像标记

- [ ] 使用提交 SHA 标记:
  - 格式: `<registry>/image:commit-<sha>`
- [ ] 使用分支名称标记:
  - 格式: `<registry>/image:branch-<name>`
- [ ] 仅 main 分支使用 `latest` 标签
- [ ] 语义版本标签(可选):
  - 格式: `<registry>/image:v1.2.3`

**验证步骤**:
```bash
# 查看推送的标签
docker images <registry>/ecommerce-backend

# 或查看仓库
# GitLab: Packages & Registries → Container Registry
# GitHub: Packages
```

### 镜像安全

- [ ] 镜像扫描已启用
- [ ] 漏洞报告可用
- [ ] 高危漏洞阻止部署(可选)
- [ ] 定期更新基础镜像

**验证步骤**:
```bash
# 使用 Trivy 扫描
trivy image <registry>/ecommerce-backend:latest

# 或使用 Docker Scout
docker scout cves <registry>/ecommerce-backend:latest
```

## 部署阶段

### 环境配置

- [ ] 预发布环境已配置:
  - [ ] URL/IP 地址
  - [ ] 访问凭证
  - [ ] Docker Compose 或 Kubernetes 配置
- [ ] 生产环境已配置:
  - [ ] URL/IP 地址
  - [ ] 访问凭证
  - [ ] 高可用性设置

**验证步骤**:
```bash
# 测试服务器连接
ssh user@staging-server
ssh user@production-server

# 验证 Docker 可用
ssh user@staging-server docker ps
```

### 部署脚本

- [ ] 部署脚本存在:
  - [ ] `deploy.sh` (或 Kubernetes `deploy.sh`)
  - [ ] 权限正确(可执行)
- [ ] 脚本包含错误处理
- [ ] 健康检查已实施
- [ ] 回滚脚本可用

**验证步骤**:
```bash
# 测试部署脚本
chmod +x deploy.sh
./deploy.sh --dry-run

# 检查健康检查
curl http://staging-server/actuator/health
```

### 手动批准

- [ ] 部署到生产需要手动批准
- [ ] 批准者已配置
- [ ] 批准流程已记录
- [ ] 超时设置合理

**验证步骤**:
```yaml
# GitLab CI
deploy_production:
  stage: deploy
  when: manual  # 需要手动触发
  only:
    - main

# Jenkins
input {
    message "Deploy to production?"
    ok "Yes"
}
```

### 冒烟测试

- [ ] 部署后冒烟测试已配置
- [ ] 测试验证关键功能:
  - [ ] 前端可访问
  - [ ] 后端 API 响应
  - [ ] 数据库连接
- [ ] 测试失败时回滚

**验证步骤**:
```bash
# 手动运行冒烟测试
curl -f http://localhost:80 || exit 1
curl -f http://localhost:8080/actuator/health || exit 1
```

## 监控和通知

### 流水线监控

- [ ] 流水线状态可见
- [ ] 失败原因明确
- [ ] 构建历史可访问
- [ ] 性能指标可用:
  - [ ] 构建时间
  - [ ] 测试时间
  - [ ] 部署时间

**验证步骤**:
```bash
# GitLab: CI/CD → Pipelines
# Jenkins: Build History
# GitHub: Actions
```

### 通知配置

- [ ] 失败通知已启用:
  - [ ] Email
  - [ ] Slack/Teams/Discord
  - [ ] 其他(根据需要)
- [ ] 通知包含相关信息:
  - [ ] 失败阶段
  - [ ] 错误消息
  - [ ] 提交信息
  - [ ] 日志链接
- [ ] 成功通知(可选)

**验证步骤**:
```bash
# 触发失败流水线测试通知
# 故意引入错误并推送

# Slack webhook 测试
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test notification"}' \
  $SLACK_WEBHOOK_URL
```

### 指标收集

- [ ] 测试指标已收集:
  - [ ] 测试数量
  - [ ] 失败测试
  - [ ] 覆盖率趋势
- [ ] 构建指标已收集:
  - [ ] 构建时长
  - [ ] 成功率
  - [ ] 队列时间
- [ ] 部署指标已收集:
  - [ ] 部署频率
  - [ ] 前置时间
  - [ ] 失败率

**验证步骤**:
```bash
# 查看 Jenkins 趋势图
# Dashboard → Build History → Trends

# 或使用 Prometheus/Grafana
```

## 安全检查

### 秘密管理

- [ ] 秘密不在代码中硬编码
- [ ] 使用 CI/CD 变量存储秘密
- [ ] 秘密已屏蔽(不在日志中显示)
- [ ] 秘密定期轮换
- [ ] `.env` 文件在 `.gitignore` 中

**验证步骤**:
```bash
# 扫描仓库中的秘密
bash scripts/scan-secrets.sh

# 或使用工具
git secrets --scan
trufflehog git file://.
```

### 依赖安全

- [ ] 依赖漏洞扫描已启用
- [ ] 高危漏洞阻止构建
- [ ] 依赖更新策略已制定
- [ ] 安全补丁及时应用

**验证步骤**:
```bash
# Maven 依赖检查
mvn dependency-check:check

# 或使用 OWASP Dependency-Check
```

### 访问控制

- [ ] CI/CD 系统访问受限:
  - [ ] 用户认证已启用
  - [ ] 基于角色的访问控制
  - [ ] 审计日志已启用
- [ ] 部署服务器访问受限:
  - [ ] SSH 密钥认证
  - [ ] 防火墙规则
  - [ ] VPN/专用网络(生产)

**验证步骤**:
```bash
# 检查 SSH 配置
cat ~/.ssh/config

# 验证无密码登录
ssh user@server "echo Access OK"
```

## 文档

### CI/CD 文档

- [ ] CI/CD 设置指南存在(docs/CI_CD_SETUP.md)
- [ ] 快速入门指南存在(.ci/QUICK_START.md)
- [ ] 故障排查指南可用
- [ ] 流水线流程图可用
- [ ] 联系人和支持信息已记录

**验证步骤**:
```bash
# 检查文档文件
ls -la docs/CI_CD_SETUP.md
ls -la .ci/QUICK_START.md
ls -la README.md
```

### 运行手册

- [ ] 部署程序已记录
- [ ] 回滚程序已记录
- [ ] 常见问题和解决方案
- [ ] 紧急联系人信息
- [ ] SLA 和维护窗口

**验证步骤**:
```bash
# 审查文档完整性
# 让团队成员按文档执行部署
```

## 最终验证

### 端到端测试

- [ ] 完整流水线运行成功:
  - [ ] 构建 ✓
  - [ ] 测试 ✓
  - [ ] 推送 ✓
  - [ ] 部署预发布 ✓
  - [ ] 部署生产 ✓
- [ ] 所有阶段在预期时间内完成
- [ ] 通知正常工作
- [ ] 应用在部署后可访问

**验证步骤**:
```bash
# 推送更改触发流水线
git commit -m "test: trigger pipeline"
git push origin main

# 监控流水线
# GitLab: CI/CD → Pipelines
# Jenkins: Dashboard
# GitHub: Actions

# 验证部署
curl http://staging-server/actuator/health
curl http://production-server/actuator/health
```

### 性能基准

- [ ] 构建时间可接受:
  - [ ] 初次构建: < 10 分钟
  - [ ] 缓存构建: < 2 分钟
- [ ] 测试时间可接受:
  - [ ] 单元测试: < 2 分钟
  - [ ] 集成测试: < 5 分钟
- [ ] 部署时间可接受:
  - [ ] 预发布: < 5 分钟
  - [ ] 生产: < 10 分钟

**验证步骤**:
```bash
# 记录多次流水线运行时间
# 计算平均值
# 识别瓶颈并优化
```

## 签署

### 团队审查

- [ ] 开发团队审查完成: _________________ 日期: _________
- [ ] DevOps 团队审查完成: _________________ 日期: _________
- [ ] 安全团队审查完成: _________________ 日期: _________
- [ ] 生产发布批准: _________________ 日期: _________

### 备注

```
在此添加任何特定于设置的备注或特殊配置:




```

## 其他资源

- [CI/CD 设置指南](../docs/CI_CD_SETUP.md)
- [快速入门指南](QUICK_START.md)
- [实施总结](IMPLEMENTATION_SUMMARY.md)
- [部署指南](../docs/deployment.md)

---

**下次审查日期**: _____________
**审查频率**: 季度或重大更改后
