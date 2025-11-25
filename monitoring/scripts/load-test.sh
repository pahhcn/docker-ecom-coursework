#!/bin/bash

# 负载测试脚本
# Load Testing Script
# 用于生成流量以测试监控系统
# For generating traffic to test monitoring system

set -e

# 配置 / Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"
DURATION="${DURATION:-300}"  # 测试持续时间（秒） / Test duration in seconds
CONCURRENT="${CONCURRENT:-10}"  # 并发请求数 / Concurrent requests

echo "=========================================="
echo "E-commerce 系统负载测试"
echo "E-commerce System Load Test"
echo "=========================================="
echo "后端 URL / Backend URL: $BACKEND_URL"
echo "持续时间 / Duration: ${DURATION}s"
echo "并发数 / Concurrent: $CONCURRENT"
echo "=========================================="
echo ""

# 检查依赖 / Check dependencies
if ! command -v curl &> /dev/null; then
    echo "错误: curl 未安装 / Error: curl is not installed"
    exit 1
fi

# 创建测试产品数据 / Create test product data
create_product() {
    local id=$1
    curl -s -X POST "$BACKEND_URL/api/products" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Test Product $id\",
            \"description\": \"This is a test product for load testing\",
            \"price\": $(( RANDOM % 1000 + 1 )),
            \"stockQuantity\": $(( RANDOM % 100 + 1 )),
            \"category\": \"Test\",
            \"imageUrl\": \"https://example.com/image$id.jpg\"
        }" > /dev/null
}

# 获取所有产品 / Get all products
get_all_products() {
    curl -s "$BACKEND_URL/api/products" > /dev/null
}

# 获取单个产品 / Get single product
get_product() {
    local id=$1
    curl -s "$BACKEND_URL/api/products/$id" > /dev/null
}

# 更新产品 / Update product
update_product() {
    local id=$1
    curl -s -X PUT "$BACKEND_URL/api/products/$id" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Updated Product $id\",
            \"description\": \"Updated description\",
            \"price\": $(( RANDOM % 1000 + 1 )),
            \"stockQuantity\": $(( RANDOM % 100 + 1 )),
            \"category\": \"Updated\",
            \"imageUrl\": \"https://example.com/updated$id.jpg\"
        }" > /dev/null
}

# 删除产品 / Delete product
delete_product() {
    local id=$1
    curl -s -X DELETE "$BACKEND_URL/api/products/$id" > /dev/null
}

# 混合负载测试 / Mixed load test
mixed_load() {
    local end_time=$((SECONDS + DURATION))
    local request_count=0
    
    echo "开始负载测试... / Starting load test..."
    echo ""
    
    while [ $SECONDS -lt $end_time ]; do
        # 随机选择操作 / Randomly select operation
        local operation=$((RANDOM % 5))
        
        case $operation in
            0)
                # 70% 读取操作 / 70% read operations
                get_all_products
                ;;
            1)
                get_product $((RANDOM % 100 + 1))
                ;;
            2)
                # 20% 创建操作 / 20% create operations
                create_product $((RANDOM % 10000))
                ;;
            3)
                # 5% 更新操作 / 5% update operations
                update_product $((RANDOM % 100 + 1))
                ;;
            4)
                # 5% 删除操作 / 5% delete operations
                delete_product $((RANDOM % 100 + 1))
                ;;
        esac
        
        request_count=$((request_count + 1))
        
        # 每 100 个请求显示进度 / Show progress every 100 requests
        if [ $((request_count % 100)) -eq 0 ]; then
            local elapsed=$((SECONDS))
            local remaining=$((end_time - SECONDS))
            echo "已发送 $request_count 个请求 / Sent $request_count requests | 已用时 / Elapsed: ${elapsed}s | 剩余 / Remaining: ${remaining}s"
        fi
        
        # 短暂延迟以避免过载 / Short delay to avoid overload
        sleep 0.01
    done
    
    echo ""
    echo "=========================================="
    echo "负载测试完成 / Load test completed"
    echo "总请求数 / Total requests: $request_count"
    echo "平均 RPS / Average RPS: $((request_count / DURATION))"
    echo "=========================================="
}

# 并发负载测试 / Concurrent load test
concurrent_load() {
    echo "启动 $CONCURRENT 个并发进程... / Starting $CONCURRENT concurrent processes..."
    
    for i in $(seq 1 $CONCURRENT); do
        mixed_load &
    done
    
    # 等待所有后台进程完成 / Wait for all background processes
    wait
    
    echo ""
    echo "所有并发进程已完成 / All concurrent processes completed"
}

# 主函数 / Main function
main() {
    # 检查后端是否可用 / Check if backend is available
    if ! curl -s -f "$BACKEND_URL/actuator/health" > /dev/null; then
        echo "错误: 无法连接到后端服务 / Error: Cannot connect to backend service"
        echo "请确保后端服务正在运行 / Please ensure backend service is running"
        exit 1
    fi
    
    echo "后端服务健康检查通过 / Backend service health check passed"
    echo ""
    
    # 运行并发负载测试 / Run concurrent load test
    concurrent_load
}

# 运行主函数 / Run main function
main
