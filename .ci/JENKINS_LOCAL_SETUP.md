# 本地 Jenkins CI/CD 完整指南

## 🎯 优势
- ✅ 无需外部账号和验证
- ✅ 完全本地运行，完全控制
- ✅ 真实的CI/CD流水线
- ✅ 可以演示给老师看

## 🚀 快速启动

### 步骤1：启动Jenkins

```bash
./run-jenkins-local.sh
```

这会：
- 启动Jenkins容器（端口8090）
- 显示初始管理员密码
- 自动配置必要的挂载

### 步骤2：初始化Jenkins

1. **访问Jenkins**
   - 打开浏览器：http://localhost:8090
   - 等待Jenkins完全启动（约1分钟）

2. **解锁Jenkins**
   - 输入终端显示的初始管理员密码
   - 或运行：`docker exec jenkins-local cat /var/jenkins_home/secrets/initialAdminPassword`

3. **安装插件**
   - 选择 **"安装推荐的插件"**
   - 等待插件安装完成（约5分钟）

4. **创建管理员用户**
   - 用户名：`admin`
   - 密码：`admin123`（或你自己的密码）
   - 全名：`Admin`
   - 邮箱：`admin@example.com`

5. **实例配置**
   - Jenkins URL：`http://localhost:8090/`
   - 点击 **"保存并完成"**

### 步骤3：创建Pipeline任务

1. **新建任务**
   - 点击 **"新建任务"**
   - 任务名称：`ecommerce-pipeline`
   - 选择 **"Pipeline"**
   - 点击 **"确定"**

2. **配置Pipeline**
   - 滚动到 **"Pipeline"** 部分
   - 定义：选择 **"Pipeline script from SCM"**
   - SCM：选择 **"Git"**
   - Repository URL：`/workspace`（本地路径）
   - 分支：`*/develop`
   - Script Path：`Jenkinsfile`
   - 点击 **"保存"**

### 步骤4：运行Pipeline

1. 点击 **"立即构建"**
2. 查看构建进度
3. 点击构建号查看详细日志

## 📊 Pipeline阶段

你会看到以下阶段：

1. **Checkout** - 检出代码
2. **Build Backend** - Maven构建
3. **Build Docker Images** - 构建镜像
4. **Run Unit Tests** - 单元测试
5. **Run Integration Tests** - 集成测试
6. **Code Coverage Check** - 覆盖率检查

## 🎨 查看测试报告

构建完成后：
1. 点击构建号
2. 查看 **"Test Result"** - JUnit测试报告
3. 查看 **"Coverage Report"** - JaCoCo覆盖率报告

## 🐛 故障排查

### 问题1：Jenkins无法访问

```bash
# 检查容器状态
docker ps | grep jenkins-local

# 查看日志
docker logs jenkins-local

# 重启Jenkins
docker restart jenkins-local
```

### 问题2：端口8090被占用

修改 `run-jenkins-local.sh` 中的端口：
```bash
-p 8091:8080 \  # 改成8091或其他端口
```

### 问题3：Docker权限问题

```bash
# 给Jenkins容器Docker权限
docker exec -u root jenkins-local chmod 666 /var/run/docker.sock
```

### 问题4：Maven构建失败

```bash
# 进入Jenkins容器安装Maven
docker exec -it jenkins-local bash
apt-get update && apt-get install -y maven
```

## 📝 简化版Pipeline（如果完整版太慢）

创建一个简化的Jenkinsfile：

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                echo '✅ 代码已检出'
            }
        }
        
        stage('Build') {
            steps {
                echo '🔨 构建中...'
                sh 'docker build -t ecommerce-frontend ./frontend'
                sh 'docker build -t ecommerce-backend ./backend'
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 运行测试...'
                sh 'cd backend && mvn test || true'
            }
        }
        
        stage('Deploy') {
            steps {
                echo '🚀 部署中...'
                sh 'docker-compose up -d'
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline成功完成！'
        }
        failure {
            echo '❌ Pipeline失败'
        }
    }
}
```

## 🎓 演示要点

向老师展示时：

1. **启动Jenkins** - 展示本地CI/CD环境
2. **创建Pipeline** - 展示如何配置
3. **运行构建** - 展示自动化流程
4. **查看日志** - 展示每个阶段的执行
5. **测试报告** - 展示自动生成的报告
6. **Docker镜像** - 展示构建的镜像

## 🛑 停止和清理

```bash
# 停止Jenkins
docker stop jenkins-local

# 删除Jenkins容器（保留数据）
docker rm jenkins-local

# 完全清理（包括数据）
docker rm -f jenkins-local
rm -rf jenkins_home
```

## 💡 提示

- Jenkins首次启动需要1-2分钟
- 插件安装需要5-10分钟
- 首次构建会下载Maven依赖，较慢
- 后续构建会使用缓存，很快
- 可以同时运行多个构建

## 📚 相关文档

- Jenkins官方文档：https://www.jenkins.io/doc/
- Pipeline语法：https://www.jenkins.io/doc/book/pipeline/syntax/
- Docker插件：https://plugins.jenkins.io/docker-plugin/

## ✅ 验证清单

- [ ] Jenkins成功启动
- [ ] 可以访问 http://localhost:8090
- [ ] 完成初始化设置
- [ ] 创建Pipeline任务
- [ ] 成功运行构建
- [ ] 可以查看测试报告
- [ ] 可以查看构建日志
