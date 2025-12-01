#!/bin/bash

# 配置 Jenkins 容器访问 Minikube

echo "🔧 配置 Jenkins 访问 Minikube..."

# 检查 Jenkins 容器是否运行
if ! docker ps | grep -q jenkins-local; then
    echo "❌ Jenkins 容器未运行，请先启动 Jenkins"
    exit 1
fi

# 获取 Minikube IP
echo ""
echo "📡 获取 Minikube 信息..."
MINIKUBE_IP=$(minikube ip)
MINIKUBE_API="https://${MINIKUBE_IP}:8443"

echo "Minikube IP: $MINIKUBE_IP"
echo "Kubernetes API: $MINIKUBE_API"

# 安装 kubectl 和 minikube 到 Jenkins 容器
echo ""
echo "📦 安装 kubectl 和 minikube..."
docker exec -u root jenkins-local bash -c '
    if ! command -v kubectl &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq curl
        curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
        echo "✅ kubectl 已安装"
    else
        echo "✅ kubectl 已存在"
    fi
'

# 从宿主机复制 minikube
if command -v minikube &> /dev/null; then
    echo "📦 复制 minikube 到 Jenkins 容器..."
    MINIKUBE_PATH=$(which minikube)
    docker cp $MINIKUBE_PATH jenkins-local:/usr/local/bin/minikube
    docker exec -u root jenkins-local chmod +x /usr/local/bin/minikube
    echo "✅ minikube 已复制"
fi

# 复制证书到 Jenkins 容器
echo ""
echo "📋 配置证书和 kubeconfig..."
docker exec -u root jenkins-local bash -c '
    mkdir -p /var/jenkins_home/.kube
    mkdir -p /var/jenkins_home/.minikube/profiles/minikube
    mkdir -p /root/.minikube/profiles/minikube
'

# 复制证书文件
docker cp ~/.minikube/ca.crt jenkins-local:/var/jenkins_home/.minikube/ca.crt
docker cp ~/.minikube/profiles/minikube/client.crt jenkins-local:/var/jenkins_home/.minikube/profiles/minikube/client.crt
docker cp ~/.minikube/profiles/minikube/client.key jenkins-local:/var/jenkins_home/.minikube/profiles/minikube/client.key

# 也复制到 /root 目录（因为 Jenkins 以 root 运行）
docker exec -u root jenkins-local bash -c '
    cp -r /var/jenkins_home/.minikube/* /root/.minikube/
'

# 生成修正后的 kubeconfig
echo ""
echo "📝 生成 kubeconfig..."
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
"

# 设置权限
docker exec -u root jenkins-local bash -c '
    chown -R jenkins:jenkins /var/jenkins_home/.kube
    chown -R jenkins:jenkins /var/jenkins_home/.minikube
    chmod 600 /var/jenkins_home/.kube/config
    chmod 600 /var/jenkins_home/.minikube/profiles/minikube/client.key
'

# 验证配置
echo ""
echo "🧪 验证 Kubernetes 访问..."
if docker exec jenkins-local kubectl get nodes 2>&1 | grep -q "minikube"; then
    echo "✅ 可以访问 Kubernetes 集群"
    docker exec jenkins-local kubectl get nodes
else
    echo "⚠️  Kubernetes 访问失败，检查配置..."
    docker exec jenkins-local kubectl cluster-info
fi

# 验证 minikube
echo ""
echo "🧪 验证 minikube 命令..."
if docker exec jenkins-local minikube version 2>&1 | grep -q "minikube version"; then
    echo "✅ minikube 命令可用"
    docker exec jenkins-local minikube version
else
    echo "⚠️  minikube 命令不可用"
fi

echo ""
echo "✅ 配置完成！"
echo ""
echo "📊 环境信息:"
echo "   Kubernetes API: $MINIKUBE_API"
echo "   Kubeconfig: /var/jenkins_home/.kube/config"
echo "   证书目录: /var/jenkins_home/.minikube/"
echo ""
echo "🧪 测试命令:"
echo "   docker exec jenkins-local kubectl get nodes"
echo "   docker exec jenkins-local minikube status"
echo ""
echo "💡 现在可以在 Jenkins Pipeline 中使用 kubectl 和 minikube 命令了"
