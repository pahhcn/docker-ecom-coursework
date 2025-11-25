#!/bin/bash

# Demo Setup Script for E-commerce Docker System
# 电子商务Docker系统演示设置脚本
#
# This script prepares the system for demonstration by:
# 此脚本通过以下方式为演示准备系统：
# 1. Cleaning up existing containers and volumes
#    清理现有容器和卷
# 2. Building fresh images
#    构建新镜像
# 3. Starting all services
#    启动所有服务
# 4. Seeding demo data
#    填充演示数据
# 5. Verifying system health
#    验证系统健康状况

set -e  # Exit on error / 出错时退出

# Colors for output / 输出颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color / 无颜色

# Function to print colored messages / 打印彩色消息的函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Check if Docker is running / 检查Docker是否运行
check_docker() {
    print_header "Checking Docker / 检查Docker"
    
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        print_error "Docker未运行。请先启动Docker。"
        exit 1
    fi
    
    print_success "Docker is running / Docker正在运行"
}

# Clean up existing containers and volumes / 清理现有容器和卷
cleanup() {
    print_header "Cleaning up existing environment / 清理现有环境"
    
    print_info "Stopping containers / 停止容器..."
    docker-compose down -v 2>/dev/null || true
    
    print_info "Removing old images (optional) / 删除旧镜像（可选）..."
    # Uncomment to remove old images / 取消注释以删除旧镜像
    # docker-compose down --rmi all
    
    print_info "Pruning unused resources / 清理未使用的资源..."
    docker system prune -f > /dev/null 2>&1 || true
    
    print_success "Cleanup complete / 清理完成"
}

# Build Docker images / 构建Docker镜像
build_images() {
    print_header "Building Docker images / 构建Docker镜像"
    
    print_info "Building frontend image / 构建前端镜像..."
    docker-compose build frontend
    
    print_info "Building backend image / 构建后端镜像..."
    docker-compose build backend
    
    print_info "Pulling database image / 拉取数据库镜像..."
    docker-compose pull mysql
    
    print_success "All images built successfully / 所有镜像构建成功"
}

# Start services / 启动服务
start_services() {
    print_header "Starting services / 启动服务"
    
    print_info "Starting database first / 首先启动数据库..."
    docker-compose up -d mysql
    
    print_info "Waiting for database to be healthy / 等待数据库健康..."
    sleep 10
    
    # Wait for MySQL to be ready / 等待MySQL准备就绪
    MAX_TRIES=30
    TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        if docker-compose exec -T mysql mysqladmin ping -h localhost --silent > /dev/null 2>&1; then
            print_success "Database is ready / 数据库已就绪"
            break
        fi
        TRIES=$((TRIES+1))
        echo -n "."
        sleep 2
    done
    
    if [ $TRIES -eq $MAX_TRIES ]; then
        print_error "Database failed to start / 数据库启动失败"
        exit 1
    fi
    
    print_info "Starting backend service / 启动后端服务..."
    docker-compose up -d backend
    
    print_info "Waiting for backend to be healthy / 等待后端健康..."
    sleep 15
    
    # Wait for backend to be ready / 等待后端准备就绪
    MAX_TRIES=30
    TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
            print_success "Backend is ready / 后端已就绪"
            break
        fi
        TRIES=$((TRIES+1))
        echo -n "."
        sleep 2
    done
    
    if [ $TRIES -eq $MAX_TRIES ]; then
        print_error "Backend failed to start / 后端启动失败"
        docker-compose logs backend
        exit 1
    fi
    
    print_info "Starting frontend service / 启动前端服务..."
    docker-compose up -d frontend
    
    sleep 5
    
    print_success "All services started / 所有服务已启动"
}

# Seed demo data / 填充演示数据
seed_data() {
    print_header "Seeding demo data / 填充演示数据"
    
    # Array of demo products / 演示产品数组
    declare -a products=(
        '{"name":"MacBook Pro 16\"","description":"Powerful laptop with M3 Pro chip, 16GB RAM, 512GB SSD. Perfect for developers and creative professionals.","price":2499.99,"stockQuantity":15,"category":"Laptops","imageUrl":"https://via.placeholder.com/300x200?text=MacBook+Pro"}'
        '{"name":"Dell XPS 13","description":"Ultra-portable laptop with Intel i7, 16GB RAM, 512GB SSD. Sleek design with InfinityEdge display.","price":1299.99,"stockQuantity":25,"category":"Laptops","imageUrl":"https://via.placeholder.com/300x200?text=Dell+XPS+13"}'
        '{"name":"iPhone 15 Pro","description":"Latest iPhone with A17 Pro chip, 256GB storage, titanium design, and advanced camera system.","price":999.99,"stockQuantity":50,"category":"Smartphones","imageUrl":"https://via.placeholder.com/300x200?text=iPhone+15+Pro"}'
        '{"name":"Samsung Galaxy S24","description":"Flagship Android phone with Snapdragon 8 Gen 3, 256GB storage, and stunning AMOLED display.","price":899.99,"stockQuantity":40,"category":"Smartphones","imageUrl":"https://via.placeholder.com/300x200?text=Galaxy+S24"}'
        '{"name":"Sony WH-1000XM5","description":"Industry-leading noise cancelling headphones with exceptional sound quality and 30-hour battery life.","price":399.99,"stockQuantity":30,"category":"Audio","imageUrl":"https://via.placeholder.com/300x200?text=Sony+WH-1000XM5"}'
        '{"name":"AirPods Pro 2","description":"Premium wireless earbuds with active noise cancellation and spatial audio support.","price":249.99,"stockQuantity":60,"category":"Audio","imageUrl":"https://via.placeholder.com/300x200?text=AirPods+Pro"}'
        '{"name":"iPad Air","description":"Versatile tablet with M1 chip, 10.9-inch Liquid Retina display, perfect for work and entertainment.","price":599.99,"stockQuantity":35,"category":"Tablets","imageUrl":"https://via.placeholder.com/300x200?text=iPad+Air"}'
        '{"name":"Samsung Galaxy Tab S9","description":"Premium Android tablet with S Pen, 11-inch display, and DeX mode for productivity.","price":799.99,"stockQuantity":20,"category":"Tablets","imageUrl":"https://via.placeholder.com/300x200?text=Galaxy+Tab+S9"}'
        '{"name":"LG 27\" 4K Monitor","description":"Professional 4K UHD monitor with IPS panel, HDR10 support, and USB-C connectivity.","price":449.99,"stockQuantity":18,"category":"Monitors","imageUrl":"https://via.placeholder.com/300x200?text=LG+4K+Monitor"}'
        '{"name":"Logitech MX Master 3S","description":"Advanced wireless mouse with ergonomic design, customizable buttons, and precision tracking.","price":99.99,"stockQuantity":45,"category":"Accessories","imageUrl":"https://via.placeholder.com/300x200?text=MX+Master+3S"}'
    )
    
    # Add each product / 添加每个产品
    for i in "${!products[@]}"; do
        product="${products[$i]}"
        print_info "Adding product $((i+1))/${#products[@]} / 添加产品 $((i+1))/${#products[@]}..."
        
        response=$(curl -s -X POST http://localhost:8080/api/products \
            -H "Content-Type: application/json" \
            -d "$product")
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Product added successfully / 产品添加成功"
        else
            print_warning "Failed to add product / 产品添加失败"
        fi
        
        sleep 0.5
    done
    
    print_success "Demo data seeded successfully / 演示数据填充成功"
}

# Verify system health / 验证系统健康
verify_system() {
    print_header "Verifying system health / 验证系统健康"
    
    # Check containers / 检查容器
    print_info "Checking container status / 检查容器状态..."
    docker-compose ps
    
    echo ""
    
    # Check frontend / 检查前端
    print_info "Testing frontend / 测试前端..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Frontend is accessible at http://localhost"
        print_success "前端可访问：http://localhost"
    else
        print_error "Frontend is not accessible / 前端不可访问"
    fi
    
    # Check backend / 检查后端
    print_info "Testing backend API / 测试后端API..."
    if curl -f http://localhost:8080/api/products > /dev/null 2>&1; then
        product_count=$(curl -s http://localhost:8080/api/products | grep -o '"id"' | wc -l)
        print_success "Backend API is accessible at http://localhost:8080/api/products"
        print_success "后端API可访问：http://localhost:8080/api/products"
        print_success "Products in database: $product_count / 数据库中的产品数：$product_count"
    else
        print_error "Backend API is not accessible / 后端API不可访问"
    fi
    
    # Check database / 检查数据库
    print_info "Testing database connection / 测试数据库连接..."
    if docker-compose exec -T mysql mysqladmin ping -h localhost --silent > /dev/null 2>&1; then
        print_success "Database is healthy / 数据库健康"
    else
        print_error "Database is not healthy / 数据库不健康"
    fi
    
    echo ""
    print_success "System verification complete / 系统验证完成"
}

# Display summary / 显示摘要
display_summary() {
    print_header "Demo Environment Ready! / 演示环境已就绪！"
    
    echo -e "${GREEN}✓${NC} All services are running / 所有服务正在运行"
    echo -e "${GREEN}✓${NC} Demo data has been seeded / 演示数据已填充"
    echo -e "${GREEN}✓${NC} System health verified / 系统健康已验证"
    echo ""
    echo -e "${BLUE}Access Points / 访问点：${NC}"
    echo -e "  Frontend / 前端:        ${GREEN}http://localhost${NC}"
    echo -e "  Backend API / 后端API:  ${GREEN}http://localhost:8080/api/products${NC}"
    echo -e "  Health Check / 健康检查: ${GREEN}http://localhost:8080/actuator/health${NC}"
    echo ""
    echo -e "${BLUE}Useful Commands / 有用的命令：${NC}"
    echo -e "  View logs / 查看日志:           ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  Stop services / 停止服务:       ${YELLOW}docker-compose down${NC}"
    echo -e "  Restart service / 重启服务:     ${YELLOW}docker-compose restart <service>${NC}"
    echo ""
    echo -e "${BLUE}Next Steps / 下一步：${NC}"
    echo -e "  1. Open browser to http://localhost"
    echo -e "     在浏览器中打开 http://localhost"
    echo -e "  2. Review the demo script at docs/demo-script.md"
    echo -e "     查看演示脚本：docs/demo-script.md"
    echo -e "  3. Start recording your demonstration!"
    echo -e "     开始录制您的演示！"
    echo ""
}

# Main execution / 主执行流程
main() {
    print_header "E-commerce Docker System - Demo Setup"
    print_header "电子商务Docker系统 - 演示设置"
    
    check_docker
    cleanup
    build_images
    start_services
    seed_data
    verify_system
    display_summary
}

# Run main function / 运行主函数
main
