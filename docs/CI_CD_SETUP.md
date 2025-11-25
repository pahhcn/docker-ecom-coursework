# CI/CD 流水线设置指南

## 概述

本项目包含三种 CI/CD 流水线配置：
1. **GitLab CI**（`.gitlab-ci.yml`）- 用于 GitLab 仓库
2. **Jenkins**（`Jenkinsfile`）- 用于 Jenkins 自动化服务器
3. **GitHub Actions**（`.github/workflows/ci-cd.yml`）- 用于 GitHub 仓库

所有流水线遵循相同的工作流：构建 → 测试 → 推送 → 部署

## 流水线阶段

### 1. 构建阶段
- 使用 Maven 编译后端 Java 应用
- 为前端、后端和数据库服务构建 Docker 镜像
- 使用提交 SHA 和分支名称标记镜像
- 缓存 Maven 依赖以加快构建速度

### 2. 测试阶段
- **单元测试**：运行所有单元测试并生成 JaCoCo 覆盖率报告
- **集成测试**：使用 TestContainers 运行集成测试
- **基于属性的测试**：运行 jqwik 属性测试（每个测试 100+ 次迭代）
- 生成测试报告和覆盖率指标
- 强制执行 80% 代码覆盖率阈值

### 3. 推送阶段
- 将 Docker 镜像推送到容器仓库
- 使用提交 SHA 标记镜像以实现可追溯性
- 仅为主分支标记 `latest`
- 需要测试成功完成

### 4. 部署阶段
- **预发布**：部署到预发布环境（develop 分支）
- **生产**：部署到生产环境（main 分支）
- 部署需要手动批准
- 部署后运行冒烟测试

## GitLab CI 设置

### 前置要求
- 启用 CI/CD 的 GitLab 仓库
- 带有 Docker 执行器的 GitLab Runner
- 容器仓库访问权限

### 配置步骤

1. **设置 CI/CD 变量**（设置 → CI/CD → 变量）：
   ```
   CI_REGISTRY_USER: 您的仓库用户名
   CI_REGISTRY_PASSWORD: 您的仓库密码
   CI_REGISTRY: 您的仓库 URL（例如：registry.gitlab.com）
   SLACK_WEBHOOK_URL: （可选）用于通知
   ```

2. **启用 GitLab 容器仓库**：
   - 转到设置 → 通用 → 可见性
   - 启用容器仓库

3. **配置 GitLab Runner**：
   ```bash
   # 安装 GitLab Runner
   curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
   sudo apt-get install gitlab-runner
   
   # 注册 runner
   sudo gitlab-runner register
   ```

4. **推送 `.gitlab-ci.yml`** 到仓库：
   ```bash
   git add .gitlab-ci.yml
   git commit -m "ci: 添加 GitLab CI/CD 流水线"
   git push origin main
   ```

### 流水线触发器
- 推送到 `main` 或 `develop` 分支时自动触发
- 合并请求时自动触发
- 手动部署阶段

## Jenkins 设置

### 前置要求
- Jenkins 服务器（2.400+）
- Jenkins 代理上安装 Docker
- 所需的 Jenkins 插件：
  - Docker Pipeline
  - JaCoCo
  - JUnit
  - HTML Publisher
  - Git

### 配置步骤

1. **安装所需插件**：
   - 转到管理 Jenkins → 管理插件
   - 安装：Docker Pipeline、JaCoCo、JUnit、HTML Publisher

2. **配置 Docker 凭证**：
   - 转到管理 Jenkins → 管理凭证
   - 添加凭证：
     - ID：`docker-credentials-id`
     - 类型：用户名和密码
     - 用户名：您的 Docker 仓库用户名
     - 密码：您的 Docker 仓库密码

3. **添加仓库 URL**：
   - 为 `docker-registry-url` 添加凭证
   - 类型：秘密文本
   - 秘密：您的仓库 URL

4. **创建流水线任务**：
   - 新建项目 → 流水线
   - 名称：`ecommerce-docker-pipeline`
   - 流水线定义：来自 SCM 的流水线脚本
   - SCM：Git
   - 仓库 URL：您的仓库 URL
   - 脚本路径：`Jenkinsfile`

5. **配置 Webhook**（可选）：
   - 转到您的 Git 仓库设置
   - 添加指向的 webhook：`http://jenkins-url/github-webhook/`

### 流水线触发器
- 每 5 分钟轮询 SCM：`H/5 * * * *`
- 从 Jenkins UI 手动触发
- Git 推送时的 Webhook 触发

## GitHub Actions 设置

### 前置要求
- GitHub 仓库
- GitHub 容器仓库（ghcr.io）或 Docker Hub 访问权限

### 配置步骤

1. **启用 GitHub Actions**：
   - 转到仓库设置 → Actions → 通用
   - 允许所有操作和可重用工作流

2. **配置秘密**（设置 → 秘密和变量 → Actions）：
   ```
   GITHUB_TOKEN: （自动提供）
   SLACK_WEBHOOK_URL: （可选）用于通知
   ```

3. **启用 GitHub 容器仓库**：
   - 包会自动发布到 ghcr.io
   - 镜像位置：`ghcr.io/username/repository/service:tag`

4. **推送工作流文件**到仓库：
   ```bash
   git add .github/workflows/ci-cd.yml
   git commit -m "ci: 添加 GitHub Actions 工作流"
   git push origin main
   ```

### 流水线触发器
- 推送到 `main` 或 `develop` 分支时自动触发
- Pull Request 时自动触发
- 手动工作流调度

## 测试配置

### JaCoCo 覆盖率报告

流水线使用 JaCoCo 强制执行 80% 代码覆盖率：

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <id>jacoco-check</id>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <rules>
                    <rule>
                        <element>PACKAGE</element>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.80</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

### TestContainers 集成

集成测试使用 TestContainers 启动真实的 MySQL 容器：

```java
@Testcontainers
@SpringBootTest
public class IntegrationTest {
    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");
    
    // 测试...
}
```

### 基于属性的测试

属性测试使用 jqwik 运行 100+ 次迭代：

```java
@Property(tries = 100)
void testProperty(@ForAll Product product) {
    // 测试实现
}
```

## 通知

### Slack 通知

配置 Slack webhook 以接收流水线通知：

1. 创建 Slack webhook：
   - 转到 Slack 应用目录
   - 搜索"Incoming Webhooks"
   - 添加到工作区并创建 webhook

2. 将 webhook URL 添加到 CI/CD 变量：
   - GitLab：`SLACK_WEBHOOK_URL`
   - Jenkins：在 Slack 插件中配置
   - GitHub：添加为仓库秘密

3. 取消注释流水线文件中的通知代码

### 邮件通知

对于 Jenkins：
1. 转到管理 Jenkins → 配置系统
2. 配置邮件通知设置
3. 在 Jenkinsfile 中添加邮件接收者

## 部署环境

### 预发布环境
- 分支：`develop`
- 部署：需要手动批准
- URL：在流水线变量中配置
- 目的：生产前测试

### 生产环境
- 分支：`main`
- 部署：需要手动批准
- URL：在流水线变量中配置
- 目的：实时生产系统

## 冒烟测试

部署后，流水线运行冒烟测试：

```bash
# 检查前端是否可访问
curl -f http://localhost:80 || exit 1

# 检查后端健康端点
curl -f http://localhost:8080/actuator/health || exit 1
```

## 故障排查

### 流水线在构建阶段失败

**问题**：Maven 构建失败
**解决方案**：
- 检查 Java 版本（需要 JDK 17）
- 清除 Maven 缓存：`mvn clean`
- 检查 `pom.xml` 中的依赖冲突

### 流水线在测试阶段失败

**问题**：测试失败或超时
**解决方案**：
- 检查 TestContainers 是否有 Docker 访问权限
- 增加流水线中的测试超时时间
- 查看测试日志以了解具体失败原因
- 确保 MySQL 服务健康

### 流水线在推送阶段失败

**问题**：无法推送到仓库
**解决方案**：
- 验证仓库凭证是否正确
- 检查仓库 URL 是否可访问
- 确保仓库有适当的权限
- 验证 Docker 登录是否成功

### 流水线在部署阶段失败

**问题**：部署失败
**解决方案**：
- 检查 Docker Compose 文件是否有效
- 验证所有必需的环境变量是否已设置
- 确保目标服务器已安装 Docker
- 检查到部署服务器的网络连接

### 覆盖率检查失败

**问题**：代码覆盖率低于 80%
**解决方案**：
- 为未覆盖的代码添加更多单元测试
- 查看 JaCoCo 报告：`backend/target/site/jacoco/index.html`
- 专注于服务层和控制器层
- 从覆盖率中排除生成的代码

## 最佳实践

1. **分支保护**：
   - 合并前需要 CI 检查通过
   - 需要代码审查批准
   - 防止直接推送到 main

2. **镜像标记**：
   - 始终使用提交 SHA 标记以实现可追溯性
   - 仅为主分支使用 `latest` 标签
   - 考虑为发布使用语义版本控制

3. **秘密管理**：
   - 永远不要将秘密提交到仓库
   - 使用 CI/CD 变量存储敏感数据
   - 定期轮换凭证

4. **测试策略**：
   - 每次提交都运行单元测试
   - 合并前运行集成测试
   - 运行属性测试以验证正确性
   - 保持高代码覆盖率（>80%）

5. **部署策略**：
   - 始终先部署到预发布环境
   - 生产部署需要手动批准
   - 部署后运行冒烟测试
   - 准备好回滚计划

## 监控流水线性能

### GitLab CI
- 查看流水线持续时间：CI/CD → 流水线
- 检查任务日志以查找瓶颈
- 监控 runner 利用率

### Jenkins
- 查看构建历史和趋势
- 使用 Blue Ocean 进行可视化流水线视图
- 监控构建队列和执行器使用情况

### GitHub Actions
- 查看工作流运行：Actions 选项卡
- 检查任务执行时间
- 监控 runner 使用情况和计费

## 维护

### 定期任务
- 每月更新基础 Docker 镜像
- 每季度更新 Maven 依赖
- 审查和更新测试覆盖率目标
- 每 90 天轮换凭证
- 从仓库清理旧的 Docker 镜像

### 流水线更新
- 首先在功能分支中测试流水线更改
- 记录所有流水线修改
- 保持流水线文件在分支间同步
- 版本控制所有 CI/CD 配置

## 其他资源

- [GitLab CI/CD 文档](https://docs.gitlab.com/ee/ci/)
- [Jenkins 流水线文档](https://www.jenkins.io/doc/book/pipeline/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [JaCoCo 文档](https://www.jacoco.org/jacoco/trunk/doc/)
- [TestContainers 文档](https://www.testcontainers.org/)
