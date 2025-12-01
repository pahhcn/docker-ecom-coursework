#!/bin/bash

# Kubernetes 服务访问脚本
# 通过端口转发让宿主机可以访问 minikube 中的服务

echo "🌐 设置 Kubernetes 服务访问..."
echo ""

# 检查 minikube 状态
if ! minikube status > /dev/null 2>&1; then
    echo "❌ minikube 未运行"
    exit 1
fi

# 停止已有的端口转发
echo "清理旧的端口转发..."
pkill -f "kubectl.*port-forward" 2>/dev/null || true
sleep 2

# 前端服务端口转发
echo "📦 启动前端服务端口转发 (localhost:8082 -> frontend:80)..."
nohup minikube kubectl -- port-forward -n ecommerce service/frontend-service 8082:80 > /tmp/k8s-frontend-forward.log 2>&1 &
FRONTEND_PID=$!

# 后端服务端口转发
echo "📦 启动后端服务端口转发 (localhost:8080 -> backend:8080)..."
nohup minikube kubectl -- port-forward -n ecommerce service/backend-service 8080:8080 > /tmp/k8s-backend-forward.log 2>&1 &
BACKEND_PID=$!

# 等待端口转发启动
sleep 5

# 验证服务
echo ""
echo "🔍 验证服务..."

if curl -s http://localhost:8082/health > /dev/null 2>&1; then
    echo "✅ 前端服务可访问"
else
    echo "⚠️  前端服务暂时不可用，请稍等..."
fi

if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ 后端服务可访问"
else
    echo "⚠️  后端服务暂时不可用，请稍等..."
fi

echo ""
echo "✅ 端口转发已启动！"
echo ""
echo "📋 访问地址:"
echo "   前端应用: http://localhost:8082"
echo "   后端 API: http://localhost:8080/api/products"
echo "   后端健康: http://localhost:8080/actuator/health"
echo ""
echo "📊 查看日志:"
echo "   前端转发: tail -f /tmp/k8s-frontend-forward.log"
echo "   后端转发: tail -f /tmp/k8s-backend-forward.log"
echo ""
echo "🛑 停止端口转发:"
echo "   pkill -f 'kubectl.*port-forward'"
echo ""
echo "💡 提示: 端口转发在后台运行，关闭终端不会停止"
