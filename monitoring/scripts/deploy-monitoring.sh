#!/bin/bash

# 监控栈部署脚本
# Monitoring Stack Deployment Script
# 用于快速部署和验证监控系统
# For quick deployment and verification of monitoring system

set -e

# 颜色定义 / Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息 / Print colored messages
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

# 检查 Docker 是否运行 / Check if Docker is running
check_docker() {
    print_info "检查 Docker 状态... / Checking Docker status..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker 未运行，请先启动 Docker / Docker is not running, please start Docker first"
        exit 1
    fi
    print_success "Docker 正在运行 / Docker is running"
}

# 检查 Docker Compose 是否可用 / Check if Docker Compose is available
check_docker_compose() {
    print_info "检查 Docker Compose... / Checking Docker Compose..."
    if ! docker-compose --version > /dev/null 2>&1; then
        print_error "Docker Compose 未安装 / Docker Compose is not installed"
        exit 1
    fi
    print_success "Docker Compose 可用 / Docker Compose is available"
}

# 停止现有服务 / Stop existing services
stop_services() {
    print_info "停止现有服务... / Stopping existing services..."
    docker-compose -f docker-compose.monitoring.yml down > /dev/null 2>&1 || true
    print_success "现有服务已停止 / Existing services stopped"
}

# 构建镜像 / Build images
build_images() {
    print_info "构建 Docker 镜像... / Building Docker images..."
    docker-compose -f docker-compose.monitoring.yml build --no-cache backend frontend
    print_success "镜像构建完成 / Images built successfully"
}

# 启动服务 / Start services
start_services() {
    print_info "启动监控栈... / Starting monitoring stack..."
    docker-compose -f docker-compose.monitoring.yml up -d
    print_success "监控栈已启动 / Monitoring stack started"
}

# 等待服务就绪 / Wait for services to be ready
wait_for_services() {
    print_info "等待服务就绪... / Waiting for services to be ready..."
    
    local max_attempts=60
    local attempt=0
    
    # 等待后端 / Wait for backend
    print_info "等待后端服务... / Waiting for backend service..."
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
            print_success "后端服务就绪 / Backend service ready"
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "后端服务启动超时 / Backend service startup timeout"
        return 1
    fi
    
    # 等待 Prometheus / Wait for Prometheus
    print_info "等待 Prometheus... / Waiting for Prometheus..."
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:9090/-/healthy > /dev/null 2>&1; then
            print_success "Prometheus 就绪 / Prometheus ready"
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "Prometheus 启动超时 / Prometheus startup timeout"
        return 1
    fi
    
    # 等待 Grafana / Wait for Grafana
    print_info "等待 Grafana... / Waiting for Grafana..."
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:3000/api/health > /dev/null 2>&1; then
            print_success "Grafana 就绪 / Grafana ready"
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "Grafana 启动超时 / Grafana startup timeout"
        return 1
    fi
}

# 验证监控配置 / Verify monitoring configuration
verify_monitoring() {
    print_info "验证监控配置... / Verifying monitoring configuration..."
    
    # 检查 Prometheus 目标 / Check Prometheus targets
    print_info "检查 Prometheus 目标... / Checking Prometheus targets..."
    local targets=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"up"' | wc -l)
    print_success "发现 $targets 个健康目标 / Found $targets healthy targets"
    
    # 检查后端指标端点 / Check backend metrics endpoint
    print_info "检查后端指标端点... / Checking backend metrics endpoint..."
    if curl -s http://localhost:8080/actuator/prometheus | grep -q "jvm_memory_used_bytes"; then
        print_success "后端指标端点正常 / Backend metrics endpoint working"
    else
        print_warning "后端指标端点可能有问题 / Backend metrics endpoint may have issues"
    fi
    
    # 检查 Grafana 数据源 / Check Grafana datasource
    print_info "检查 Grafana 数据源... / Checking Grafana datasource..."
    if curl -s -u admin:admin http://localhost:3000/api/datasources | grep -q "Prometheus"; then
        print_success "Grafana 数据源已配置 / Grafana datasource configured"
    else
        print_warning "Grafana 数据源可能未配置 / Grafana datasource may not be configured"
    fi
}

# 显示访问信息 / Display access information
show_access_info() {
    echo ""
    echo "=========================================="
    echo "监控栈部署完成！/ Monitoring Stack Deployed!"
    echo "=========================================="
    echo ""
    echo "访问以下 URL: / Access the following URLs:"
    echo ""
    echo "  📊 Grafana:       http://localhost:3000"
    echo "     用户名/Username: admin"
    echo "     密码/Password:   admin"
    echo ""
    echo "  📈 Prometheus:    http://localhost:9090"
    echo ""
    echo "  🔔 Alertmanager:  http://localhost:9093"
    echo ""
    echo "  📦 cAdvisor:      http://localhost:8082"
    echo ""
    echo "  🌐 Frontend:      http://localhost:8081"
    echo ""
    echo "  🔧 Backend API:   http://localhost:8080"
    echo "     健康检查/Health: http://localhost:8080/actuator/health"
    echo "     指标/Metrics:    http://localhost:8080/actuator/prometheus"
    echo ""
    echo "=========================================="
    echo ""
    echo "下一步: / Next steps:"
    echo "  1. 访问 Grafana 并查看仪表板"
    echo "     Visit Grafana and view dashboards"
    echo ""
    echo "  2. 运行负载测试以生成指标"
    echo "     Run load test to generate metrics:"
    echo "     ./monitoring/scripts/load-test.sh"
    echo ""
    echo "  3. 查看服务日志"
    echo "     View service logs:"
    echo "     docker-compose -f docker-compose.monitoring.yml logs -f"
    echo ""
    echo "=========================================="
}

# 主函数 / Main function
main() {
    echo ""
    echo "=========================================="
    echo "E-commerce 监控栈部署"
    echo "E-commerce Monitoring Stack Deployment"
    echo "=========================================="
    echo ""
    
    # 检查前置条件 / Check prerequisites
    check_docker
    check_docker_compose
    
    # 停止现有服务 / Stop existing services
    stop_services
    
    # 构建镜像 / Build images
    if [ "${SKIP_BUILD}" != "true" ]; then
        build_images
    else
        print_warning "跳过镜像构建 / Skipping image build"
    fi
    
    # 启动服务 / Start services
    start_services
    
    # 等待服务就绪 / Wait for services
    if ! wait_for_services; then
        print_error "服务启动失败，请查看日志 / Service startup failed, please check logs"
        print_info "查看日志命令 / View logs command:"
        print_info "docker-compose -f docker-compose.monitoring.yml logs"
        exit 1
    fi
    
    # 验证监控配置 / Verify monitoring
    verify_monitoring
    
    # 显示访问信息 / Show access info
    show_access_info
}

# 运行主函数 / Run main function
main
