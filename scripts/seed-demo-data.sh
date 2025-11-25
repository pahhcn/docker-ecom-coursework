#!/bin/bash

# Demo Data Seeding Script
# 演示数据填充脚本
#
# This script populates the database with sample product data
# 此脚本使用示例产品数据填充数据库

set -e

# Colors / 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration / 配置
API_URL="${API_URL:-http://localhost:8080}"
PRODUCTS_ENDPOINT="${API_URL}/api/products"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Demo Data Seeding Script${NC}"
echo -e "${BLUE}演示数据填充脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if backend is accessible / 检查后端是否可访问
echo -e "${BLUE}[INFO]${NC} Checking backend availability / 检查后端可用性..."
if ! curl -f "${API_URL}/actuator/health" > /dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} Backend is not accessible at ${API_URL}"
    echo -e "${RED}[错误]${NC} 后端在 ${API_URL} 不可访问"
    echo -e "${YELLOW}[提示]${NC} Please ensure the backend service is running"
    echo -e "${YELLOW}[提示]${NC} 请确保后端服务正在运行"
    exit 1
fi
echo -e "${GREEN}[SUCCESS]${NC} Backend is accessible / 后端可访问"
echo ""

# Demo products data / 演示产品数据
declare -a products=(
    # Laptops / 笔记本电脑
    '{
        "name": "MacBook Pro 16\"",
        "description": "强大的笔记本电脑，配备M3 Pro芯片、16GB内存、512GB固态硬盘。非常适合开发人员和创意专业人士。",
        "price": 2499.99,
        "stockQuantity": 15,
        "category": "笔记本电脑",
        "imageUrl": "https://via.placeholder.com/300x200?text=MacBook+Pro"
    }'
    '{
        "name": "Dell XPS 13",
        "description": "超便携笔记本电脑，配备Intel i7、16GB内存、512GB固态硬盘。时尚设计，配备InfinityEdge显示屏。",
        "price": 1299.99,
        "stockQuantity": 25,
        "category": "笔记本电脑",
        "imageUrl": "https://via.placeholder.com/300x200?text=Dell+XPS+13"
    }'
    '{
        "name": "ThinkPad X1 Carbon",
        "description": "商务级笔记本电脑，配备Intel i7、16GB内存、1TB固态硬盘。轻薄耐用，续航时间长。",
        "price": 1599.99,
        "stockQuantity": 20,
        "category": "笔记本电脑",
        "imageUrl": "https://via.placeholder.com/300x200?text=ThinkPad+X1"
    }'
    
    # Smartphones / 智能手机
    '{
        "name": "iPhone 15 Pro",
        "description": "最新款iPhone，配备A17 Pro芯片、256GB存储、钛金属设计和先进的相机系统。",
        "price": 999.99,
        "stockQuantity": 50,
        "category": "智能手机",
        "imageUrl": "https://via.placeholder.com/300x200?text=iPhone+15+Pro"
    }'
    '{
        "name": "Samsung Galaxy S24",
        "description": "旗舰Android手机，配备骁龙8 Gen 3、256GB存储和令人惊叹的AMOLED显示屏。",
        "price": 899.99,
        "stockQuantity": 40,
        "category": "智能手机",
        "imageUrl": "https://via.placeholder.com/300x200?text=Galaxy+S24"
    }'
    '{
        "name": "Google Pixel 8 Pro",
        "description": "纯净的Android体验，配备Google Tensor G3芯片、出色的相机和AI功能。",
        "price": 899.99,
        "stockQuantity": 30,
        "category": "智能手机",
        "imageUrl": "https://via.placeholder.com/300x200?text=Pixel+8+Pro"
    }'
    
    # Audio / 音频设备
    '{
        "name": "Sony WH-1000XM5",
        "description": "业界领先的降噪耳机，音质卓越，续航时间长达30小时。",
        "price": 399.99,
        "stockQuantity": 30,
        "category": "音频设备",
        "imageUrl": "https://via.placeholder.com/300x200?text=Sony+WH-1000XM5"
    }'
    '{
        "name": "AirPods Pro 2",
        "description": "高级无线耳塞，具有主动降噪和空间音频支持。",
        "price": 249.99,
        "stockQuantity": 60,
        "category": "音频设备",
        "imageUrl": "https://via.placeholder.com/300x200?text=AirPods+Pro"
    }'
    '{
        "name": "Bose QuietComfort 45",
        "description": "舒适的降噪耳机，音质平衡，适合长时间佩戴。",
        "price": 329.99,
        "stockQuantity": 25,
        "category": "音频设备",
        "imageUrl": "https://via.placeholder.com/300x200?text=Bose+QC45"
    }'
    
    # Tablets / 平板电脑
    '{
        "name": "iPad Air",
        "description": "多功能平板电脑，配备M1芯片、10.9英寸Liquid Retina显示屏，非常适合工作和娱乐。",
        "price": 599.99,
        "stockQuantity": 35,
        "category": "平板电脑",
        "imageUrl": "https://via.placeholder.com/300x200?text=iPad+Air"
    }'
    '{
        "name": "Samsung Galaxy Tab S9",
        "description": "高级Android平板电脑，配备S Pen、11英寸显示屏和DeX模式，提高生产力。",
        "price": 799.99,
        "stockQuantity": 20,
        "category": "平板电脑",
        "imageUrl": "https://via.placeholder.com/300x200?text=Galaxy+Tab+S9"
    }'
    
    # Monitors / 显示器
    '{
        "name": "LG 27\" 4K显示器",
        "description": "专业级4K UHD显示器，配备IPS面板、HDR10支持和USB-C连接。",
        "price": 449.99,
        "stockQuantity": 18,
        "category": "显示器",
        "imageUrl": "https://via.placeholder.com/300x200?text=LG+4K+Monitor"
    }'
    '{
        "name": "Dell UltraSharp 27\"",
        "description": "色彩准确的显示器，适合设计师和摄影师，支持99% sRGB色域。",
        "price": 499.99,
        "stockQuantity": 15,
        "category": "显示器",
        "imageUrl": "https://via.placeholder.com/300x200?text=Dell+UltraSharp"
    }'
    
    # Accessories / 配件
    '{
        "name": "Logitech MX Master 3S",
        "description": "高级无线鼠标，人体工学设计，可自定义按钮和精确跟踪。",
        "price": 99.99,
        "stockQuantity": 45,
        "category": "配件",
        "imageUrl": "https://via.placeholder.com/300x200?text=MX+Master+3S"
    }'
    '{
        "name": "Keychron K8 Pro",
        "description": "机械键盘，支持有线和无线连接，可热插拔开关。",
        "price": 109.99,
        "stockQuantity": 35,
        "category": "配件",
        "imageUrl": "https://via.placeholder.com/300x200?text=Keychron+K8"
    }'
    '{
        "name": "Anker PowerCore 20000",
        "description": "大容量移动电源，支持快速充电，可为多个设备充电。",
        "price": 49.99,
        "stockQuantity": 80,
        "category": "配件",
        "imageUrl": "https://via.placeholder.com/300x200?text=Anker+PowerCore"
    }'
)

# Seed products / 填充产品
echo -e "${BLUE}[INFO]${NC} Starting to seed products / 开始填充产品..."
echo ""

success_count=0
fail_count=0
total=${#products[@]}

for i in "${!products[@]}"; do
    product="${products[$i]}"
    product_num=$((i+1))
    
    echo -e "${BLUE}[${product_num}/${total}]${NC} Adding product / 添加产品..."
    
    # Extract product name for display / 提取产品名称用于显示
    product_name=$(echo "$product" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"name"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
    
    # Send POST request / 发送POST请求
    response=$(curl -s -w "\n%{http_code}" -X POST "${PRODUCTS_ENDPOINT}" \
        -H "Content-Type: application/json" \
        -d "$product")
    
    # Extract HTTP status code / 提取HTTP状态码
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓${NC} Successfully added: ${product_name}"
        echo -e "${GREEN}✓${NC} 成功添加：${product_name}"
        success_count=$((success_count+1))
    else
        echo -e "${RED}✗${NC} Failed to add: ${product_name} (HTTP ${http_code})"
        echo -e "${RED}✗${NC} 添加失败：${product_name} (HTTP ${http_code})"
        echo -e "${YELLOW}Response:${NC} ${response_body}"
        fail_count=$((fail_count+1))
    fi
    
    echo ""
    sleep 0.3  # Small delay to avoid overwhelming the API / 小延迟以避免压垮API
done

# Summary / 摘要
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Seeding Complete / 填充完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Successful:${NC} ${success_count}/${total} / ${GREEN}成功：${NC} ${success_count}/${total}"
if [ $fail_count -gt 0 ]; then
    echo -e "${RED}Failed:${NC} ${fail_count}/${total} / ${RED}失败：${NC} ${fail_count}/${total}"
fi
echo ""

# Verify seeded data / 验证填充的数据
echo -e "${BLUE}[INFO]${NC} Verifying seeded data / 验证填充的数据..."
product_count=$(curl -s "${PRODUCTS_ENDPOINT}" | grep -o '"id"' | wc -l)
echo -e "${GREEN}[SUCCESS]${NC} Total products in database: ${product_count}"
echo -e "${GREEN}[成功]${NC} 数据库中的产品总数：${product_count}"
echo ""

echo -e "${GREEN}✓${NC} Demo data seeding completed!"
echo -e "${GREEN}✓${NC} 演示数据填充完成！"
echo ""
echo -e "${BLUE}You can now access the frontend at:${NC} http://localhost"
echo -e "${BLUE}您现在可以访问前端：${NC} http://localhost"
