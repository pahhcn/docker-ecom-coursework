#!/bin/bash

# 安装 Jenkins Kubernetes 相关插件

echo "📦 安装 Jenkins Kubernetes 插件..."

docker exec -u root jenkins-local jenkins-plugin-cli --plugins \
  kubernetes:latest \
  kubernetes-cli:latest \
  kubernetes-credentials:latest

echo ""
echo "✅ 插件安装完成！"
echo ""
echo "请重启 Jenkins:"
echo "  docker restart jenkins-local"
