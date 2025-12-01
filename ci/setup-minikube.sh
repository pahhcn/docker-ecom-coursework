#!/bin/bash

# 安装和配置 minikube 用于本地 Kubernetes 测试

echo "📦 安装 minikube..."

# 检查系统架构
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

# 下载 minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH}
sudo install minikube-linux-${ARCH} /usr/local/bin/minikube
rm minikube-linux-${ARCH}

echo "✅ minikube 已安装"
echo ""

# 启动 minikube
echo "🚀 启动 minikube 集群..."
minikube start --driver=docker

echo ""
echo "✅ minikube 集群已启动"
echo ""

# 配置 kubectl
echo "配置 kubectl..."
mkdir -p ~/.kube
minikube kubectl -- config view --flatten > ~/.kube/config

# 复制 kubeconfig 到 Jenkins 容器
echo "复制 kubeconfig 到 Jenkins 容器..."
docker exec jenkins-local mkdir -p /var/jenkins_home/.kube
docker cp ~/.kube/config jenkins-local:/var/jenkins_home/.kube/config
docker exec -u root jenkins-local chown -R jenkins:jenkins /var/jenkins_home/.kube

echo ""
echo "✅ Kubernetes 环境配置完成！"
echo ""
echo "验证集群状态:"
kubectl get nodes

echo ""
echo "现在可以在 Jenkins 中使用 k8s 或 k8s-blue-green 部署了！"
