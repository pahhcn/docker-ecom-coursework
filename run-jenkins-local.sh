#!/bin/bash

# 本地运行Jenkins CI/CD
# 这个脚本会启动一个本地Jenkins实例来运行CI/CD流水线

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          本地 Jenkins CI/CD 快速启动                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ 错误: Docker未运行，请先启动Docker"
    exit 1
fi

echo "✅ Docker已运行"
echo ""

# 创建Jenkins数据目录
JENKINS_HOME="$PWD/jenkins_home"
mkdir -p "$JENKINS_HOME"

echo "📁 Jenkins数据目录: $JENKINS_HOME"
echo ""

# 检查是否已有Jenkins容器运行
if docker ps -a | grep -q "jenkins-local"; then
    echo "🔄 发现已存在的Jenkins容器，正在清理..."
    docker stop jenkins-local 2>/dev/null || true
    docker rm jenkins-local 2>/dev/null || true
fi

echo "🚀 启动Jenkins容器..."
echo ""

# 启动Jenkins容器
docker run -d \
  --name jenkins-local \
  -p 8090:8080 \
  -p 50000:50000 \
  -v "$JENKINS_HOME":/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/workspace \
  --user root \
  jenkins/jenkins:lts

echo "⏳ 等待Jenkins启动（约30秒）..."
sleep 30

# 获取初始管理员密码
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                Jenkins 启动成功！                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 访问地址: http://localhost:8090"
echo ""
echo "🔑 初始管理员密码:"
docker exec jenkins-local cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "密码获取中，请稍后..."
echo ""
echo "📋 下一步操作:"
echo "   1. 访问 http://localhost:8090"
echo "   2. 输入上面的初始管理员密码"
echo "   3. 选择 '安装推荐的插件'"
echo "   4. 创建管理员用户"
echo "   5. 创建新的Pipeline任务"
echo "   6. 使用项目中的 Jenkinsfile"
echo ""
echo "📝 查看Jenkins日志:"
echo "   docker logs -f jenkins-local"
echo ""
echo "🛑 停止Jenkins:"
echo "   docker stop jenkins-local"
echo ""
