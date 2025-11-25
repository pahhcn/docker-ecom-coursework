# CI/CD 快速入门指南

本指南提供快速启动 CI/CD 流水线的步骤和常见任务参考。

## 目录
1. [快速开始](#快速开始)
2. [常用命令](#常用命令)
3. [常见任务](#常见任务)
4. [故障排查](#故障排查)

## 快速开始

### 选择您的平台

<details>
<summary><b>GitLab CI</b></summary>

#### 前置要求
- GitLab 账户
- GitLab Runner (已配置)

#### 5 分钟设置

1. **配置 CI/CD 变量**
   ```
   Settings → CI/CD → Variables → Expand
   
   添加:
   - CI_REGISTRY_USER: <您的用户名>
   - CI_REGISTRY_PASSWORD: <您的密码> [屏蔽]
   - CI_REGISTRY: registry.gitlab.com
   ```

2. **启用容器仓库**
   ```
   Settings → General → Visibility → Enable Container Registry
   ```

3. **推送代码触发流水线**
   ```bash
   git add .gitlab-ci.yml
   git commit -m "ci: add GitLab CI pipeline"
   git push origin main
   ```

4. **查看流水线**
   ```
   CI/CD → Pipelines
   ```

</details>

<details>
<summary><b>Jenkins</b></summary>

#### 前置要求
- Jenkins 服务器 (2.400+)
- Docker 插件

#### 5 分钟设置

1. **安装插件**
   ```
   Manage Jenkins → Manage Plugins → Available
   
   安装:
   - Docker Pipeline
   - JaCoCo
   - JUnit
   ```

2. **添加凭证**
   ```
   Manage Jenkins → Manage Credentials
   
   添加:
   - ID: docker-credentials-id
   - Type: Username with password
   ```

3. **创建流水线任务**
   ```
   New Item → Pipeline
   Name: ecommerce-pipeline
   Pipeline script from SCM → Git
   Script Path: Jenkinsfile
   ```

4. **构建项目**
   ```
   Dashboard → ecommerce-pipeline → Build Now
   ```

</details>

<details>
<summary><b>GitHub Actions</b></summary>

#### 前置要求
- GitHub 账户
- 仓库管理员权限

#### 5 分钟设置

1. **启用 Actions**
   ```
   Settings → Actions → General
   Allow all actions and reusable workflows
   ```

2. **配置秘密** (可选)
   ```
   Settings → Secrets and variables → Actions
   
   添加:
   - SLACK_WEBHOOK_URL: <webhook-url>
   ```

3. **推送工作流**
   ```bash
   git add .github/workflows/ci-cd.yml
   git commit -m "ci: add GitHub Actions workflow"
   git push origin main
   ```

4. **查看工作流**
   ```
   Actions 选项卡
   ```

</details>

## 常用命令

### GitLab CI

```bash
# 验证 .gitlab-ci.yml 语法
gitlab-ci-lint .gitlab-ci.yml

# 手动触发流水线
# UI: CI/CD → Pipelines → Run Pipeline

# 查看流水线状态
# UI: CI/CD → Pipelines

# 下载构建产物
# UI: Pipelines → [Job] → Browse artifacts

# 重试失败的任务
# UI: Pipelines → [Pipeline] → Retry
```

### Jenkins

```bash
# 触发构建
curl -X POST http://jenkins-url/job/ecommerce-pipeline/build \
  --user username:token

# 查看控制台输出
# UI: Dashboard → [Job] → [Build #] → Console Output

# 查看测试报告
# UI: Dashboard → [Job] → [Build #] → Test Result

# 查看覆盖率报告
# UI: Dashboard → [Job] → [Build #] → Code Coverage

# 重建
# UI: Dashboard → [Job] → [Build #] → Rebuild
```

### GitHub Actions

```bash
# 手动触发工作流
# UI: Actions → [Workflow] → Run workflow

# 查看工作流运行
# UI: Actions → All workflows

# 重新运行失败的任务
# UI: Actions → [Run] → Re-run failed jobs

# 取消运行
# UI: Actions → [Run] → Cancel workflow
```

## 常见任务

### 任务 1: 触发流水线

**GitLab CI**:
```bash
# 推送代码
git push origin main

# 或手动触发
# CI/CD → Pipelines → Run Pipeline
# 选择分支 → Run Pipeline
```

**Jenkins**:
```bash
# 自动触发(通过 webhook)
git push origin main

# 或手动触发
# Dashboard → [Job] → Build Now
```

**GitHub Actions**:
```bash
# 推送代码
git push origin main

# 或手动触发
# Actions → [Workflow] → Run workflow
```

### 任务 2: 查看构建日志

**GitLab CI**:
```
CI/CD → Pipelines → [Pipeline] → [Job]
查看实时日志输出
```

**Jenkins**:
```
Dashboard → [Job] → [Build #] → Console Output
```

**GitHub Actions**:
```
Actions → [Run] → [Job]
展开步骤查看日志
```

### 任务 3: 下载构建产物

**GitLab CI**:
```
Pipelines → [Pipeline] → [Job] → Browse artifacts
或
Pipelines → [Pipeline] → Download artifacts
```

**Jenkins**:
```
Dashboard → [Job] → [Build #] → Artifacts
点击文件下载
```

**GitHub Actions**:
```
Actions → [Run] → Artifacts
下载打包的产物
```

### 任务 4: 部署到环境

**预发布环境** (自动):
```bash
# 推送到 develop 分支
git checkout develop
git merge feature/xxx
git push origin develop
# 自动部署到预发布
```

**生产环境** (手动批准):
```bash
# 推送到 main 分支
git checkout main
git merge develop
git push origin main

# GitLab: CI/CD → Pipelines → [Pipeline] → deploy_production → Play
# Jenkins: Dashboard → [Job] → [Build #] → Input Required → Proceed
# GitHub: Actions → [Run] → Review deployments → Approve
```

### 任务 5: 回滚部署

**Docker Compose**:
```bash
# SSH 到服务器
ssh user@production-server

# 停止当前版本
docker compose down

# 拉取之前的镜像
docker pull registry/ecommerce-backend:previous-sha
docker pull registry/ecommerce-frontend:previous-sha

# 更新 docker-compose.yml 中的镜像标签
# 或设置环境变量
export BACKEND_TAG=previous-sha
export FRONTEND_TAG=previous-sha

# 启动
docker compose up -d
```

**Kubernetes**:
```bash
# 查看部署历史
kubectl rollout history deployment/backend -n ecommerce

# 回滚到上一版本
kubectl rollout undo deployment/backend -n ecommerce
kubectl rollout undo deployment/frontend -n ecommerce

# 或回滚到特定版本
kubectl rollout undo deployment/backend --to-revision=2 -n ecommerce
```

### 任务 6: 查看测试报告

**GitLab CI**:
```
Pipelines → [Pipeline] → Tests 选项卡
查看失败的测试和覆盖率
```

**Jenkins**:
```
Dashboard → [Job] → [Build #] → Test Result
点击查看详细信息

覆盖率:
Dashboard → [Job] → [Build #] → Code Coverage
```

**GitHub Actions**:
```
Actions → [Run] → Summary
查看测试结果和覆盖率报告
```

### 任务 7: 重新运行失败的任务

**GitLab CI**:
```
Pipelines → [Pipeline] → Retry
或仅重试失败的任务
```

**Jenkins**:
```
Dashboard → [Job] → [Build #] → Rebuild
```

**GitHub Actions**:
```
Actions → [Run] → Re-run failed jobs
或 Re-run all jobs
```

## 故障排查

### 问题 1: 流水线失败

**诊断**:
1. 查看失败的任务日志
2. 识别错误消息
3. 检查最近的代码更改

**常见解决方案**:
- **构建失败**: 检查 Dockerfile 和依赖
- **测试失败**: 运行本地测试,修复代码
- **推送失败**: 验证仓库凭证
- **部署失败**: 检查部署脚本和目标服务器

### 问题 2: 镜像推送失败

**检查**:
```bash
# 验证凭证
docker login <registry-url> -u <username>

# 手动推送测试
docker tag ecommerce-backend:test <registry>/ecommerce-backend:test
docker push <registry>/ecommerce-backend:test
```

**解决方案**:
- 更新 CI/CD 变量中的凭证
- 检查仓库权限
- 验证仓库 URL

### 问题 3: 测试超时

**增加超时**:

**GitLab CI**:
```yaml
test:
  timeout: 30m  # 默认 1h
```

**Jenkins**:
```groovy
options {
    timeout(time: 30, unit: 'MINUTES')
}
```

**GitHub Actions**:
```yaml
jobs:
  test:
    timeout-minutes: 30  # 默认 360
```

### 问题 4: 缓存未工作

**清除缓存**:

**GitLab CI**:
```
CI/CD → Pipelines → Clear Runner Caches
```

**Jenkins**:
```
Dashboard → [Job] → Workspace → Wipe Out Workspace
```

**GitHub Actions**:
```bash
# 缓存自动管理,或删除缓存
Settings → Actions → Caches → Delete
```

### 问题 5: 部署权限错误

**检查**:
```bash
# 测试 SSH 连接
ssh user@server

# 验证 Docker 访问
ssh user@server docker ps

# 检查文件权限
ssh user@server ls -la /opt/app
```

**解决方案**:
- 添加 SSH 密钥到 CI/CD
- 确保用户在 docker 组中
- 修复目录权限

## 快速参考

### 流水线阶段

| 阶段 | 目的 | 时长 | 失败原因 |
|------|------|------|----------|
| 构建 | 构建 Docker 镜像 | 2-5 分钟 | Dockerfile 错误,依赖问题 |
| 测试 | 运行所有测试 | 2-5 分钟 | 测试失败,覆盖率不足 |
| 推送 | 推送镜像到仓库 | 1-2 分钟 | 凭证错误,网络问题 |
| 部署 | 部署到环境 | 2-5 分钟 | 脚本错误,服务器问题 |

### 环境变量

**GitLab CI**:
```yaml
CI_COMMIT_SHA       # 提交 SHA
CI_COMMIT_REF_NAME  # 分支名称
CI_REGISTRY         # 容器仓库 URL
CI_REGISTRY_USER    # 仓库用户名
```

**Jenkins**:
```groovy
GIT_COMMIT          # 提交 SHA
GIT_BRANCH          # 分支名称
BUILD_NUMBER        # 构建编号
WORKSPACE           # 工作空间路径
```

**GitHub Actions**:
```yaml
GITHUB_SHA          # 提交 SHA
GITHUB_REF          # 引用名称
GITHUB_ACTOR        # 触发用户
GITHUB_REPOSITORY   # 仓库名称
```

### 有用的链接

**文档**:
- [完整设置指南](../docs/CI_CD_SETUP.md)
- [检查清单](CHECKLIST.md)
- [实施总结](IMPLEMENTATION_SUMMARY.md)

**平台文档**:
- [GitLab CI 文档](https://docs.gitlab.com/ee/ci/)
- [Jenkins 文档](https://www.jenkins.io/doc/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

**工具**:
- [Docker 文档](https://docs.docker.com/)
- [Maven 文档](https://maven.apache.org/)
- [JaCoCo 文档](https://www.jacoco.org/jacoco/)

## 最佳实践

### DO ✅

- 在推送前本地测试
- 编写有意义的提交消息
- 保持流水线快速(< 15 分钟)
- 监控流水线状态
- 定期更新依赖

### DON'T ❌

- 提交秘密到仓库
- 跳过测试
- 直接推送到 main
- 忽略流水线失败
- 使用默认密码

## 获取帮助

**日志和调试**:
```bash
# 本地运行测试
cd backend
mvn clean test

# 本地构建镜像
docker build -t test ./backend

# 本地运行容器
docker run --rm test
```

**联系支持**:
- DevOps 团队: devops@example.com
- Slack 频道: #ci-cd-support
- 创建 Issue: [仓库 Issues](https://github.com/org/repo/issues)

---

**提示**: 将此页面加入书签以便快速参考!
