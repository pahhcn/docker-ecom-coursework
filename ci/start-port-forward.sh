#!/bin/bash

# 启动 K8s 端口转发脚本
# 在宿主机上运行此脚本，让浏览器可以访问 K8s 服务

NAMESPACE="ecommerce"

echo "========================================="
echo "🚀 启动 K8s 端口转发"
echo "========================================="

# 停止旧的端口转发
pkill -f 'kubectl.*port-forward.*ecommerce' 2>/dev/null || true
sleep 2

echo "启动前端端口转发 (8082 -> 80)..."
nohup minikube kubectl -- port-forward -n $NAMESPACE --address 0.0.0.0 service/frontend-service 8082:80 > /tmp/k8s-frontend.log 2>&1 &
FRONTEND_PID=$!

echo "启动后端端口转发 (8083 -> 8080)..."
nohup minikube kubectl -- port-forward -n $NAMESPACE --address 0.0.0.0 service/backend-service 8083:8080 > /tmp/k8s-backend.log 2>&1 &
BACKEND_PID=$!

sleep 3

echo ""
echo "✅ 端口转发已启动"
echo ""
echo "🌐 访问地址:"
echo "   前端: http://localhost:8082"
echo "   后端API: http://localhost:8083/api/products"
echo "   健康检查: http://localhost:8083/actuator/health"
echo ""
echo "📋 进程信息:"
echo "   前端 PID: $FRONTEND_PID"
echo "   后端 PID: $BACKEND_PID"
echo ""
echo "🛑 停止端口转发:"
echo "   pkill -f 'kubectl.*port-forward.*ecommerce'"
echo ""
