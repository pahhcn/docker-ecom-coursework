# APM 监控系统设置指南
# APM Monitoring System Setup Guide

## 概述 / Overview

本文档介绍如何为 E-commerce Docker 系统设置和配置 APM（应用性能监控）监控栈。监控栈包括：
This document describes how to set up and configure the APM (Application Performance Monitoring) stack for the E-commerce Docker system. The monitoring stack includes:

- **Prometheus**: 指标收集和存储 / Metrics collection and storage
- **Grafana**: 可视化仪表板 / Visualization dashboards
- **Alertmanager**: 告警管理 / Alert management
- **Exporters**: 各种指标导出器 / Various metrics exporters
  - MySQL Exporter: 数据库指标 / Database metrics
  - Nginx Exporter: Web 服务器指标 / Web server metrics
  - Node Exporter: 系统指标 / System metrics
  - cAdvisor: 容器指标 / Container metrics

## 架构 / Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        监控架构 / Monitoring Architecture        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   Frontend   │────▶│ Nginx        │────▶│   Grafana    │    │
│  │   (Nginx)    │     │ Exporter     │     │ (Dashboard)  │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│                                                     │            │
│  ┌──────────────┐     ┌──────────────┐            │            │
│  │   Backend    │────▶│ Micrometer   │            │            │
│  │ (Spring Boot)│     │ Prometheus   │            │            │
│  └──────────────┘     └──────────────┘            │            │
│                                                     │            │
│  ┌──────────────┐     ┌──────────────┐            │            │
│  │   Database   │────▶│    MySQL     │            │            │
│  │   (MySQL)    │     │   Exporter   │            │            │
│  └──────────────┘     └──────────────┘            │            │
│                                                     │            │
│  ┌──────────────┐     ┌──────────────┐            │            │
│  │  Containers  │────▶│   cAdvisor   │            │            │
│  │              │     │              │            │            │
│  └──────────────┘     └──────────────┘            │            │
│                                                     │            │
│  ┌──────────────┐                                  │            │
│  │    System    │────▶│     Node     │            │            │
│  │              │     │   Exporter   │            │            │
│  └──────────────┘     └──────────────┘            │            │
│                              │                     │            │
│                              ▼                     ▼            │
│                       ┌──────────────┐     ┌──────────────┐    │
│                       │  Prometheus  │────▶│ Alertmanager │    │
│                       │  (Storage)   │     │  (Alerts)    │    │
│                       └──────────────┘     └──────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 快速开始 / Quick Start

### 1. 启动监控栈 / Start Monitoring Stack

使用包含监控服务的 Docker Compose 配置：
Use the Docker Compose configuration with monitoring services:

```bash
# 启动所有服务（包括监控） / Start all services (including monitoring)
docker-compose -f docker-compose.monitoring.yml up -d

# 查看服务状态 / Check service status
docker-compose -f docker-compose.monitoring.yml ps

# 查看日志 / View logs
docker-compose -f docker-compose.monitoring.yml logs -f
```

### 2. 访问监控界面 / Access Monitoring Interfaces

启动后，可以通过以下 URL 访问各个监控服务：
After startup, you can access the monitoring services at:

| 服务 / Service | URL | 默认凭据 / Default Credentials |
|---------------|-----|-------------------------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| cAdvisor | http://localhost:8082 | - |

### 3. 配置 Grafana / Configure Grafana

首次登录 Grafana 后：
After first login to Grafana:

1. 使用默认凭据登录：admin / admin
   Login with default credentials: admin / admin

2. 系统会提示修改密码（可选）
   You'll be prompted to change password (optional)

3. Prometheus 数据源已自动配置
   Prometheus datasource is automatically configured

4. 预配置的仪表板已自动加载
   Pre-configured dashboards are automatically loaded

## 监控指标说明 / Monitoring Metrics Explanation

### 应用指标 / Application Metrics

#### 后端 API 指标 / Backend API Metrics

通过 Micrometer 和 Spring Boot Actuator 暴露：
Exposed via Micrometer and Spring Boot Actuator:

- **请求率 / Request Rate**: `http_server_requests_seconds_count`
  - 每秒处理的 HTTP 请求数 / HTTP requests per second
  
- **响应时间 / Response Time**: `http_server_requests_seconds`
  - P50, P95, P99 响应时间百分位数 / Response time percentiles
  
- **错误率 / Error Rate**: `http_server_requests_seconds_count{status=~"5.."}`
  - 5xx 错误响应的比率 / Ratio of 5xx error responses
  
- **JVM 内存 / JVM Memory**: `jvm_memory_used_bytes`, `jvm_memory_max_bytes`
  - 堆内存使用情况 / Heap memory usage
  
- **JVM 线程 / JVM Threads**: `jvm_threads_live`, `jvm_threads_daemon`
  - 活跃线程数 / Active thread count
  
- **垃圾回收 / Garbage Collection**: `jvm_gc_pause_seconds`
  - GC 暂停时间 / GC pause time

访问后端指标端点：
Access backend metrics endpoint:
```bash
curl http://localhost:8080/actuator/prometheus
```

### 数据库指标 / Database Metrics

通过 MySQL Exporter 收集：
Collected via MySQL Exporter:

- **连接数 / Connections**: `mysql_global_status_threads_connected`
  - 当前活跃连接数 / Current active connections
  
- **查询率 / Query Rate**: `mysql_global_status_queries`
  - 每秒查询数 / Queries per second
  
- **慢查询 / Slow Queries**: `mysql_global_status_slow_queries`
  - 慢查询计数 / Slow query count
  
- **缓冲池 / Buffer Pool**: `mysql_global_status_innodb_buffer_pool_*`
  - InnoDB 缓冲池使用情况 / InnoDB buffer pool usage

### 系统指标 / System Metrics

通过 Node Exporter 收集：
Collected via Node Exporter:

- **CPU 使用率 / CPU Usage**: `node_cpu_seconds_total`
  - CPU 时间分布 / CPU time distribution
  
- **内存使用 / Memory Usage**: `node_memory_*`
  - 内存使用详情 / Memory usage details
  
- **磁盘 I/O / Disk I/O**: `node_disk_*`
  - 磁盘读写速率 / Disk read/write rates
  
- **网络流量 / Network Traffic**: `node_network_*`
  - 网络接收/发送字节数 / Network receive/transmit bytes

### 容器指标 / Container Metrics

通过 cAdvisor 收集：
Collected via cAdvisor:

- **容器 CPU / Container CPU**: `container_cpu_usage_seconds_total`
  - 每个容器的 CPU 使用 / CPU usage per container
  
- **容器内存 / Container Memory**: `container_memory_usage_bytes`
  - 每个容器的内存使用 / Memory usage per container
  
- **容器网络 / Container Network**: `container_network_*`
  - 容器网络流量 / Container network traffic

## 告警规则 / Alert Rules

系统配置了以下关键告警规则：
The system is configured with the following critical alert rules:

### 应用告警 / Application Alerts

1. **高错误率 / High Error Rate**
   - 条件 / Condition: 错误率 > 5% 持续 5 分钟 / Error rate > 5% for 5 minutes
   - 严重性 / Severity: Critical
   
2. **高响应时间 / High Response Time**
   - 条件 / Condition: P95 响应时间 > 1 秒持续 5 分钟 / P95 response time > 1s for 5 minutes
   - 严重性 / Severity: Warning
   
3. **服务宕机 / Service Down**
   - 条件 / Condition: 服务不可用超过 1 分钟 / Service unavailable for 1 minute
   - 严重性 / Severity: Critical
   
4. **高 JVM 内存使用 / High JVM Memory Usage**
   - 条件 / Condition: 堆内存使用 > 85% 持续 5 分钟 / Heap memory > 85% for 5 minutes
   - 严重性 / Severity: Warning

### 数据库告警 / Database Alerts

1. **高连接数 / High Database Connections**
   - 条件 / Condition: 连接数 > 80 持续 5 分钟 / Connections > 80 for 5 minutes
   - 严重性 / Severity: Warning
   
2. **数据库宕机 / Database Down**
   - 条件 / Condition: 数据库不可用超过 1 分钟 / Database unavailable for 1 minute
   - 严重性 / Severity: Critical
   
3. **高慢查询率 / High Slow Query Rate**
   - 条件 / Condition: 慢查询 > 10/s 持续 5 分钟 / Slow queries > 10/s for 5 minutes
   - 严重性 / Severity: Warning

### 基础设施告警 / Infrastructure Alerts

1. **容器重启 / Container Restart**
   - 条件 / Condition: 检测到容器重启 / Container restart detected
   - 严重性 / Severity: Warning
   
2. **高 CPU 使用率 / High CPU Usage**
   - 条件 / Condition: CPU 使用 > 85% 持续 5 分钟 / CPU usage > 85% for 5 minutes
   - 严重性 / Severity: Warning
   
3. **高内存使用率 / High Memory Usage**
   - 条件 / Condition: 内存使用 > 85% 持续 5 分钟 / Memory usage > 85% for 5 minutes
   - 严重性 / Severity: Warning
   
4. **磁盘空间不足 / Low Disk Space**
   - 条件 / Condition: 可用磁盘空间 < 10% / Available disk space < 10%
   - 严重性 / Severity: Critical

## 负载测试 / Load Testing

使用提供的负载测试脚本生成流量以测试监控系统：
Use the provided load testing script to generate traffic for testing the monitoring system:

```bash
# 运行默认负载测试（5 分钟，10 个并发） / Run default load test (5 minutes, 10 concurrent)
./monitoring/scripts/load-test.sh

# 自定义参数 / Custom parameters
DURATION=600 CONCURRENT=20 ./monitoring/scripts/load-test.sh

# 指定后端 URL / Specify backend URL
BACKEND_URL=http://localhost:8080 ./monitoring/scripts/load-test.sh
```

负载测试脚本会：
The load test script will:

1. 创建随机产品 / Create random products
2. 查询产品列表 / Query product lists
3. 更新产品信息 / Update product information
4. 删除产品 / Delete products
5. 模拟真实用户行为模式 / Simulate realistic user behavior patterns

在 Grafana 中观察：
Observe in Grafana:
- 请求率增加 / Request rate increase
- 响应时间变化 / Response time changes
- 资源使用情况 / Resource usage
- 错误率（如果有）/ Error rate (if any)

## 仪表板说明 / Dashboard Explanation

### E-commerce 系统概览仪表板 / E-commerce System Overview Dashboard

预配置的仪表板包含以下面板：
The pre-configured dashboard contains the following panels:

1. **API 请求率 / API Request Rate**
   - 显示每秒 API 请求数 / Shows API requests per second
   - 帮助识别流量模式 / Helps identify traffic patterns
   
2. **API 响应时间 P95 / API Response Time P95**
   - 显示 95% 请求的响应时间 / Shows response time for 95% of requests
   - 用于性能监控 / Used for performance monitoring
   
3. **API 错误率 / API Error Rate**
   - 显示 5xx 错误的百分比 / Shows percentage of 5xx errors
   - 帮助快速发现问题 / Helps quickly identify issues
   
4. **JVM 堆内存使用 / JVM Heap Memory Usage**
   - 显示 Java 堆内存使用情况 / Shows Java heap memory usage
   - 帮助识别内存泄漏 / Helps identify memory leaks
   
5. **MySQL 连接数 / MySQL Connections**
   - 显示数据库连接数 / Shows database connection count
   - 监控连接池健康状况 / Monitors connection pool health
   
6. **MySQL 查询率 / MySQL Query Rate**
   - 显示数据库查询速率 / Shows database query rate
   - 包括慢查询统计 / Includes slow query statistics

## 告警配置 / Alert Configuration

### 配置邮件告警 / Configure Email Alerts

编辑 `monitoring/alertmanager/alertmanager.yml`：
Edit `monitoring/alertmanager/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

receivers:
  - name: 'critical-alerts'
    email_configs:
      - to: 'ops-team@example.com'
        headers:
          Subject: '[CRITICAL] {{ .GroupLabels.alertname }}'
```

### 配置 Slack 告警 / Configure Slack Alerts

```yaml
receivers:
  - name: 'critical-alerts'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts-critical'
        title: '[CRITICAL] {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

### 配置 Webhook 告警 / Configure Webhook Alerts

```yaml
receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://your-webhook-endpoint/alerts'
        send_resolved: true
```

## 数据保留 / Data Retention

### Prometheus 数据保留 / Prometheus Data Retention

默认保留 30 天的指标数据：
Default retention is 30 days of metrics data:

```yaml
command:
  - '--storage.tsdb.retention.time=30d'
```

修改保留时间：
To modify retention time:

```bash
# 编辑 docker-compose.monitoring.yml
# Edit docker-compose.monitoring.yml
# 修改 prometheus 服务的 command 参数
# Modify the command parameter of prometheus service
```

### 备份监控数据 / Backup Monitoring Data

```bash
# 备份 Prometheus 数据 / Backup Prometheus data
docker run --rm -v prometheus-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/prometheus-backup-$(date +%Y%m%d).tar.gz /data

# 备份 Grafana 数据 / Backup Grafana data
docker run --rm -v grafana-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/grafana-backup-$(date +%Y%m%d).tar.gz /data
```

## 故障排查 / Troubleshooting

### Prometheus 无法抓取指标 / Prometheus Cannot Scrape Metrics

1. 检查目标服务是否运行：
   Check if target service is running:
   ```bash
   docker-compose -f docker-compose.monitoring.yml ps
   ```

2. 检查网络连接：
   Check network connectivity:
   ```bash
   docker exec ecommerce-prometheus wget -O- http://backend:8080/actuator/prometheus
   ```

3. 查看 Prometheus 日志：
   View Prometheus logs:
   ```bash
   docker-compose -f docker-compose.monitoring.yml logs prometheus
   ```

### Grafana 无法连接 Prometheus / Grafana Cannot Connect to Prometheus

1. 检查 Prometheus 是否运行：
   Check if Prometheus is running:
   ```bash
   curl http://localhost:9090/-/healthy
   ```

2. 在 Grafana 中测试数据源：
   Test datasource in Grafana:
   - 导航到 Configuration > Data Sources
   - Navigate to Configuration > Data Sources
   - 点击 Prometheus 数据源
   - Click on Prometheus datasource
   - 点击 "Test" 按钮
   - Click "Test" button

### 告警未触发 / Alerts Not Firing

1. 检查告警规则是否加载：
   Check if alert rules are loaded:
   ```bash
   curl http://localhost:9090/api/v1/rules
   ```

2. 检查 Alertmanager 是否运行：
   Check if Alertmanager is running:
   ```bash
   curl http://localhost:9093/-/healthy
   ```

3. 查看 Alertmanager 日志：
   View Alertmanager logs:
   ```bash
   docker-compose -f docker-compose.monitoring.yml logs alertmanager
   ```

## 性能优化 / Performance Optimization

### Prometheus 性能优化 / Prometheus Performance Optimization

1. **调整抓取间隔 / Adjust Scrape Interval**
   ```yaml
   global:
     scrape_interval: 30s  # 增加间隔以减少负载 / Increase interval to reduce load
   ```

2. **限制指标保留 / Limit Metrics Retention**
   ```yaml
   command:
     - '--storage.tsdb.retention.time=15d'  # 减少保留时间 / Reduce retention time
   ```

3. **增加资源限制 / Increase Resource Limits**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1.0'
         memory: 1G
   ```

### Grafana 性能优化 / Grafana Performance Optimization

1. **启用查询缓存 / Enable Query Caching**
   ```yaml
   environment:
     - GF_DATAPROXY_TIMEOUT=60
     - GF_DATAPROXY_KEEP_ALIVE_SECONDS=30
   ```

2. **限制时间范围 / Limit Time Range**
   - 在仪表板中使用较短的时间范围
   - Use shorter time ranges in dashboards
   - 避免查询过多历史数据
   - Avoid querying too much historical data

## 最佳实践 / Best Practices

1. **定期检查告警 / Regularly Check Alerts**
   - 每天查看 Alertmanager 状态
   - Check Alertmanager status daily
   - 确保关键告警正常工作
   - Ensure critical alerts are working

2. **监控监控系统 / Monitor the Monitoring System**
   - 设置 Prometheus 和 Grafana 的健康检查
   - Set up health checks for Prometheus and Grafana
   - 监控监控系统的资源使用
   - Monitor resource usage of monitoring system

3. **定期备份 / Regular Backups**
   - 每周备份 Prometheus 和 Grafana 数据
   - Backup Prometheus and Grafana data weekly
   - 测试恢复流程
   - Test recovery procedures

4. **优化查询 / Optimize Queries**
   - 使用高效的 PromQL 查询
   - Use efficient PromQL queries
   - 避免过度聚合
   - Avoid excessive aggregation
   - 使用记录规则预计算常用指标
   - Use recording rules to pre-compute common metrics

5. **文档化自定义配置 / Document Custom Configurations**
   - 记录所有自定义告警规则
   - Document all custom alert rules
   - 记录仪表板修改
   - Document dashboard modifications
   - 维护配置变更日志
   - Maintain configuration change log

## 参考资源 / References

- [Prometheus 官方文档 / Prometheus Official Documentation](https://prometheus.io/docs/)
- [Grafana 官方文档 / Grafana Official Documentation](https://grafana.com/docs/)
- [Spring Boot Actuator 文档 / Spring Boot Actuator Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Micrometer 文档 / Micrometer Documentation](https://micrometer.io/docs)
- [MySQL Exporter 文档 / MySQL Exporter Documentation](https://github.com/prometheus/mysqld_exporter)
- [Node Exporter 文档 / Node Exporter Documentation](https://github.com/prometheus/node_exporter)
- [cAdvisor 文档 / cAdvisor Documentation](https://github.com/google/cadvisor)

## 支持 / Support

如有问题或需要帮助，请：
For questions or help, please:

1. 查看故障排查部分 / Check the Troubleshooting section
2. 查看日志文件 / Check log files
3. 访问官方文档 / Visit official documentation
4. 提交 Issue / Submit an issue

---

**版本 / Version**: 1.0.0  
**最后更新 / Last Updated**: 2025-11-25  
**作者 / Author**: E-commerce DevOps Team
