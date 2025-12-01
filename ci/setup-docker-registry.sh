#!/bin/bash

# 设置本地 Docker Registry

echo "========================================="
echo "设置本地 Docker Registry"
echo "========================================="
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker 未运行"
    exit 1
fi

# 检查 Registry 是否已运行
if docker ps | grep -q registry:2; then
    echo "本地 Registry 已在运行"
    REGISTRY_RUNNING=true
else
    REGISTRY_RUNNING=false
fi

if [ "$REGISTRY_RUNNING" = false ]; then
    echo "启动本地 Docker Registry..."
    
    # 创建数据目录
    mkdir -p ~/docker-registry
    
    # 启动 Registry 容器
    docker run -d \
      --name registry \
      --restart=always \
      -p 5000:5000 \
      -v ~/docker-registry:/var/lib/registry \
      registry:2
    
    echo "等待 Registry 启动..."
    sleep 5
fi

# 验证 Registry
echo ""
echo "验证 Registry..."
if curl -s http://localhost:5000/v2/_catalog > /dev/null; then
    echo "✅ Registry 运行正常"
    echo ""
    echo "Registry 地址: localhost:5000"
    echo "查看镜像列表: curl http://localhost:5000/v2/_catalog"
else
    echo "❌ Registry 验证失败"
    exit 1
fi

# 配置 Docker 信任本地 Registry (如果需要)
echo ""
echo "配置 Docker 信任本地 Registry..."

# 检查 daemon.json 是否存在
DAEMON_JSON="/etc/docker/daemon.json"
if [ -f "$DAEMON_JSON" ]; then
    echo "daemon.json 已存在"
    if grep -q "insecure-registries" "$DAEMON_JSON"; then
        echo "insecure-registries 已配置"
    else
        echo "需要手动添加 insecure-registries 配置"
        echo "请在 $DAEMON_JSON 中添加:"
        echo '  "insecure-registries": ["localhost:5000"]'
    fi
else
    echo "创建 daemon.json..."
    sudo mkdir -p /etc/docker
    echo '{
  "insecure-registries": ["localhost:5000"]
}' | sudo tee $DAEMON_JSON > /dev/null
    
    echo "重启 Docker 服务..."
    sudo systemctl restart docker
    sleep 5
fi

# 测试推送镜像
echo ""
echo "测试推送镜像..."
docker pull hello-world:latest
docker tag hello-world:latest localhost:5000/hello-world:test
if docker push localhost:5000/hello-world:test; then
    echo "✅ 镜像推送测试成功"
    docker rmi localhost:5000/hello-world:test
else
    echo "⚠️ 镜像推送测试失败"
    echo "可能需要配置 insecure-registries"
fi

echo ""
echo "========================================="
echo "✅ Docker Registry 设置完成"
echo "========================================="
echo ""
echo "Registry 信息:"
echo "  地址: localhost:5000"
echo "  数据目录: ~/docker-registry"
echo "  容器名称: registry"
echo ""
echo "常用命令:"
echo "  查看镜像列表: curl http://localhost:5000/v2/_catalog"
echo "  查看镜像标签: curl http://localhost:5000/v2/<image-name>/tags/list"
echo "  停止 Registry: docker stop registry"
echo "  启动 Registry: docker start registry"
echo "  删除 Registry: docker rm -f registry"
echo ""
echo "推送镜像示例:"
echo "  docker tag my-image:latest localhost:5000/my-image:latest"
echo "  docker push localhost:5000/my-image:latest"
