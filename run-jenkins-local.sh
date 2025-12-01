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

# 检查并拉取Jenkins镜像
if docker images jenkins/jenkins:lts | grep -q jenkins; then
    echo "✅ 本地已有Jenkins镜像"
else
    echo "📥 本地无Jenkins镜像，正在拉取..."
    if docker pull jenkins/jenkins:lts; then
        echo "✅ Jenkins镜像拉取成功"
    else
        echo "❌ 镜像拉取失败，请检查网络连接"
        exit 1
    fi
fi
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

echo "🚀 启动Jenkins容器（使用 host 网络模式）..."
echo ""

# 启动Jenkins容器 - 使用 host 网络模式以访问 minikube
docker run -d \
  --name jenkins-local \
  --network host \
  -v "$JENKINS_HOME":/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/workspace \
  -v ~/.kube:/root/.kube \
  -v ~/.minikube:/root/.minikube \
  -v /root/.m2:/root/.m2 \
  --user root \
  -e JENKINS_OPTS="--httpPort=8090" \
  jenkins/jenkins:lts

echo "⏳ 等待Jenkins启动（约30秒）..."
sleep 30

echo "🔧 配置Jenkins环境..."

# 安装Docker CLI、docker-compose、kubectl、Maven
echo "正在安装必要工具..."
docker exec -u root jenkins-local bash -c "
    # 安装基础工具
    apt-get update -qq && \
    apt-get install -y -qq docker.io docker-compose curl wget && \
    
    # 安装 kubectl
    curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/ && \
    
    # 安装 Maven
    cd /opt && \
    (wget -q https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz || \
     wget -q https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz) && \
    tar xzf apache-maven-3.9.9-bin.tar.gz && \
    rm apache-maven-3.9.9-bin.tar.gz && \
    ln -sf /opt/apache-maven-3.9.9 /opt/maven && \
    ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn && \
    
    # 配置 kubeconfig
    mkdir -p /var/jenkins_home/.kube && \
    cp -r /root/.kube/* /var/jenkins_home/.kube/ 2>/dev/null || true && \
    
    # 修复 kubeconfig 中的路径（从宿主机路径改为容器路径）
    sed -i 's|/home/[^/]*/\.minikube|/root/.minikube|g' /root/.kube/config 2>/dev/null || true && \
    sed -i 's|/home/[^/]*/\.minikube|/root/.minikube|g' /var/jenkins_home/.kube/config 2>/dev/null || true && \
    
    chown -R jenkins:jenkins /var/jenkins_home/.kube
" > /dev/null 2>&1

echo "✅ 工具安装完成"

# 复制 minikube 到 Jenkins 容器（如果存在）
if command -v minikube &> /dev/null; then
    echo "📦 复制 minikube 到 Jenkins 容器..."
    sleep 5  # 等待容器完全启动
    MINIKUBE_PATH=$(which minikube)
    docker cp "$MINIKUBE_PATH" jenkins-local:/usr/local/bin/minikube 2>/dev/null || true
    docker exec -u root jenkins-local chmod +x /usr/local/bin/minikube 2>/dev/null || true
fi

# 配置 Minikube 证书（如果 minikube 正在运行）
if minikube status &> /dev/null; then
    echo "🔐 配置 Minikube 证书..."
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "192.168.49.2")
    MINIKUBE_API="https://${MINIKUBE_IP}:8443"
    
    # 复制证书文件
    docker exec -u root jenkins-local bash -c "
        mkdir -p /var/jenkins_home/.minikube/profiles/minikube
        mkdir -p /root/.minikube/profiles/minikube
    " 2>/dev/null || true
    
    if [ -f ~/.minikube/ca.crt ]; then
        docker cp ~/.minikube/ca.crt jenkins-local:/var/jenkins_home/.minikube/ca.crt 2>/dev/null || true
        docker cp ~/.minikube/profiles/minikube/client.crt jenkins-local:/var/jenkins_home/.minikube/profiles/minikube/client.crt 2>/dev/null || true
        docker cp ~/.minikube/profiles/minikube/client.key jenkins-local:/var/jenkins_home/.minikube/profiles/minikube/client.key 2>/dev/null || true
        
        # 生成 kubeconfig
        docker exec -u root jenkins-local bash -c "
            cat > /var/jenkins_home/.kube/config << 'EOF'
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/jenkins_home/.minikube/ca.crt
    server: ${MINIKUBE_API}
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /var/jenkins_home/.minikube/profiles/minikube/client.crt
    client-key: /var/jenkins_home/.minikube/profiles/minikube/client.key
EOF
            cp -r /var/jenkins_home/.minikube/* /root/.minikube/ 2>/dev/null || true
            chown -R jenkins:jenkins /var/jenkins_home/.kube
            chown -R jenkins:jenkins /var/jenkins_home/.minikube
            chmod 600 /var/jenkins_home/.kube/config 2>/dev/null || true
            chmod 600 /var/jenkins_home/.minikube/profiles/minikube/client.key 2>/dev/null || true
        " 2>/dev/null || true
    fi
fi

# 创建Jenkins Job配置
echo "📝 创建Pipeline任务配置..."

# 在Jenkins容器内创建Job配置（避免权限问题）
docker exec jenkins-local mkdir -p /var/jenkins_home/jobs/docker-ecom-coursework

docker exec jenkins-local bash -c 'cat > /var/jenkins_home/jobs/docker-ecom-coursework/config.xml << '\''EOF'\''
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1436.vfa_244484591f">
  <actions/>
  <description>Docker电商项目CI/CD流水线</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3964.v0767b_4b_a_0b_fa_">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.5.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/pahhcn/docker-ecom-coursework.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/develop</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPathh>Jenkinsfile</scriptPath>
 <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
'

# 重新加载Jenkins配置
sleep 5
docker exec jenkins-local curl -X POST http://localhost:8080/reload 2>/dev/null || true

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
echo "   2. 输入上面的初始管理员密码（首次启动）"
echo "   3. 选择 '安装推荐的插件'"
echo "   4. 创建管理员用户"
echo "   5. 查看自动创建的 'docker-ecom-coursework' 任务"
echo "   6. 点击 '立即构建' 开始CI/CD流水线"
echo ""
echo "🎯 网络配置:"
echo "   ✅ 使用 host 网络模式"
echo "   ✅ 可以直接访问 minikube (192.168.49.2:8443)"
echo "   ✅ 可以使用 kubectl 命令"
echo "   ✅ 可以使用 minikube 命令"
echo ""
echo "🧪 测试 Kubernetes 访问:"
echo "   docker exec jenkins-local kubectl get nodes"
echo "   docker exec jenkins-local minikube status"
echo ""
echo "📝 查看Jenkins日志:"
echo "   docker logs -f jenkins-local"
echo ""
echo "🛑 停止Jenkins:"
echo "   docker stop jenkins-local"
echo ""

# 验证安装
echo ""
echo "🔍 验证工具安装..."

# 验证 kubectl
if docker exec jenkins-local kubectl version --client > /dev/null 2>&1; then
    echo "✅ kubectl 可用"
else
    echo "⚠️  kubectl 未安装"
fi

# 验证 Maven
if docker exec jenkins-local mvn -version > /dev/null 2>&1; then
    echo "✅ Maven 可用"
    docker exec jenkins-local mvn -version | head -1
else
    echo "⚠️  Maven 未安装"
fi

# 验证 minikube
if docker exec jenkins-local minikube version > /dev/null 2>&1; then
    echo "✅ minikube 可用"
fi

# 验证 Kubernetes 访问
if docker exec jenkins-local kubectl get nodes 2>&1 | grep -q "minikube"; then
    echo "✅ 可以访问 Kubernetes 集群"
else
    echo "⚠️  Kubernetes 访问需要配置 kubeconfig"
fi
echo ""

# 安装 Jenkins Kubernetes 插件（后台执行）
echo "📦 安装 Jenkins Kubernetes 插件（后台执行）..."
(
    sleep 60  # 等待 Jenkins 完全启动
    docker exec -u root jenkins-local jenkins-plugin-cli --plugins \
        kubernetes:latest \
        kubernetes-cli:latest \
        kubernetes-credentials:latest > /dev/null 2>&1
    echo "✅ Jenkins Kubernetes 插件安装完成（需要重启 Jenkins 生效）"
) &

echo ""
