# 监控系统快速开始指南
# Monitoring System Quick Start Guide

## 简介 / Introduction

本目录包含 E-commerce 系统的完整监控解决方案，基于 Prometheus + Grafana 技术栈。
This directory contains the complete monitoring solution for the E-commerce system, based on the Prometheus + Grafana stack.

## 目录结构 / Directory Structure

```
monitoring/
├── prometheus/
│   ├── prometheus.yml          # Prometheus 主配置文件 / Main config
│   └── alerts/
│       └── alerts.yml          # 告警规则 / Alert rules
├── grafana/
│   ├── dashboards/
│   │   └── ecommerce-overview.json  # 系统概览仪表板 / Overview dashboard
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml  # 数据源配置 / Datasource config
│       └── dashboards/
│           └── dashboards.yml  # 仪表板配置 / Dashboard config
├── alertmanager/
│   └── alertmanager.yml        # 告警管理器配置 / Alertmanager config
├── scripts/
│   └── load-test.sh            # 负载测试脚本 / Load test script
└── README.md                   # 本文件 / This file
```

## 快速开始 / Quick Start

### 1. 启动监控栈 / Start Monitoring Stack

```bash
# 从项目根目录运行 / Run from project root
docker-compose -f docker-compose.monitoring.yml up -d

# 等待所有服务启动 / Wait for all services to start
docker-compose -f docker-compose.monitoring.yml ps
```

### 2. 访问监控界面 / Access Monitoring Interfaces

| 服务 / Service | URL | 用户名 / Username | 密码 / Password |
|---------------|-----|------------------|----------------|
| Grafana | http://localhost:3000 | admin | admin |
| Prometheus | http://localhost:9090 | - | - |
| Alertmanager | http://localhost:9093 | - | - |
| cAdvisor | http://localhost:8082 | - | - |

### 3. 查看仪表板 / View Dashboards

1. 登录 Grafana (http://localhost:3000)
2. 导航到 Dashboards → Browse
3. 打开 "E-commerce 系统概览" 仪表板
   Open "E-commerce System Overview" dashboard

### 4. 运行负载测试 / Run Load Test

```bash
# 生成测试流量 / Generate test traffic
./monitoring/scripts/load-test.sh

# 在 Grafana 中观察指标变化 / Observe metrics changes in Grafana
```

## 监控的指标 / Monitored Metrics

### 应用层 / Application Layer
- ✅ API 请求率 / API request rate
- ✅ API 响应时间 / API response time
- ✅ API 错误率 / API error rate
- ✅ JVM 内存使用 / JVM memory usage
- ✅ JVM 线程数 / JVM thread count
- ✅ 垃圾回收统计 / Garbage collection stats

### 数据库层 / Database Layer
- ✅ MySQL 连接数 / MySQL connections
- ✅ 查询率 / Query rate
- ✅ 慢查询 / Slow queries
- ✅ InnoDB 缓冲池 / InnoDB buffer pool

### 系统层 / System Layer
- ✅ CPU 使用率 / CPU usage
- ✅ 内存使用 / Memory usage
- ✅ 磁盘 I/O / Disk I/O
- ✅ 网络流量 / Network traffic

### 容器层 / Container Layer
- ✅ 容器 CPU / Container CPU
- ✅ 容器内存 / Container memory
- ✅ 容器网络 / Container network
- ✅ 容器重启 / Container restarts

## 告警规则 / Alert Rules

系统配置了以下告警：
The system is configured with the following alerts:

### 关键告警 / Critical Alerts
- 🔴 服务宕机 / Service down
- 🔴 数据库宕机 / Database down
- 🔴 高错误率 (>5%) / High error rate (>5%)
- 🔴 磁盘空间不足 (<10%) / Low disk space (<10%)

### 警告告警 / Warning Alerts
- 🟡 高响应时间 (P95 >1s) / High response time (P95 >1s)
- 🟡 高 JVM 内存使用 (>85%) / High JVM memory (>85%)
- 🟡 高数据库连接数 (>80) / High DB connections (>80)
- 🟡 高 CPU 使用率 (>85%) / High CPU usage (>85%)
- 🟡 高内存使用率 (>85%) / High memory usage (>85%)

## 配置说明 / Configuration

### Prometheus 配置 / Prometheus Configuration

主配置文件：`prometheus/prometheus.yml`
Main configuration: `prometheus/prometheus.yml`

- 抓取间隔：15 秒 / Scrape interval: 15s
- 评估间隔：15 秒 / Evaluation interval: 15s
- 数据保留：30 天 / Data retention: 30 days

### Grafana 配置 / Grafana Configuration

- 数据源自动配置 / Datasource auto-configured
- 仪表板自动加载 / Dashboards auto-loaded
- 默认刷新间隔：10 秒 / Default refresh: 10s

### Alertmanager 配置 / Alertmanager Configuration

- 分组等待：10 秒 / Group wait: 10s
- 分组间隔：10 秒 / Group interval: 10s
- 重复间隔：12 小时 / Repeat interval: 12h

## 常用命令 / Common Commands

### 查看服务状态 / Check Service Status
```bash
docker-compose -f docker-compose.monitoring.yml ps
```

### 查看日志 / View Logs
```bash
# 所有服务 / All services
docker-compose -f docker-compose.monitoring.yml logs -f

# 特定服务 / Specific service
docker-compose -f docker-compose.monitoring.yml logs -f prometheus
docker-compose -f docker-compose.monitoring.yml logs -f grafana
```

### 重启服务 / Restart Services
```bash
# 重启所有服务 / Restart all services
docker-compose -f docker-compose.monitoring.yml restart

# 重启特定服务 / Restart specific service
docker-compose -f docker-compose.monitoring.yml restart prometheus
```

### 停止监控栈 / Stop Monitoring Stack
```bash
docker-compose -f docker-compose.monitoring.yml down
```

### 清理数据 / Clean Up Data
```bash
# 停止并删除所有数据 / Stop and remove all data
docker-compose -f docker-compose.monitoring.yml down -v
```

## 故障排查 / Troubleshooting

### Prometheus 无法抓取指标 / Prometheus Cannot Scrape Metrics

```bash
# 检查目标状态 / Check target status
curl http://localhost:9090/api/v1/targets

# 测试后端指标端点 / Test backend metrics endpoint
curl http://localhost:8080/actuator/prometheus
```

### Grafana 无法显示数据 / Grafana Cannot Display Data

```bash
# 检查 Prometheus 连接 / Check Prometheus connection
curl http://localhost:9090/-/healthy

# 在 Grafana 中测试数据源 / Test datasource in Grafana
# Configuration → Data Sources → Prometheus → Test
```

### 告警未触发 / Alerts Not Firing

```bash
# 检查告警规则 / Check alert rules
curl http://localhost:9090/api/v1/rules

# 检查 Alertmanager / Check Alertmanager
curl http://localhost:9093/api/v1/alerts
```

## 性能建议 / Performance Recommendations

1. **调整抓取间隔 / Adjust Scrape Interval**
   - 生产环境可以增加到 30-60 秒
   - Production can increase to 30-60s

2. **限制数据保留 / Limit Data Retention**
   - 根据需求调整保留时间
   - Adjust retention based on needs

3. **优化查询 / Optimize Queries**
   - 使用较短的时间范围
   - Use shorter time ranges
   - 避免过度聚合
   - Avoid excessive aggregation

## 下一步 / Next Steps

1. ✅ 启动监控栈 / Start monitoring stack
2. ✅ 访问 Grafana 仪表板 / Access Grafana dashboards
3. ✅ 运行负载测试 / Run load test
4. ⬜ 配置告警通知（邮件/Slack）/ Configure alert notifications (Email/Slack)
5. ⬜ 创建自定义仪表板 / Create custom dashboards
6. ⬜ 设置数据备份 / Set up data backups

## 更多信息 / More Information

详细文档请参阅：
For detailed documentation, see:
- [监控设置指南 / Monitoring Setup Guide](../docs/monitoring-setup.md)
- [Prometheus 官方文档 / Prometheus Docs](https://prometheus.io/docs/)
- [Grafana 官方文档 / Grafana Docs](https://grafana.com/docs/)

## 支持 / Support

遇到问题？/ Having issues?
1. 查看故障排查部分 / Check Troubleshooting section
2. 查看日志 / Check logs
3. 访问官方文档 / Visit official docs

---

**快乐监控！/ Happy Monitoring!** 📊📈
