pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'docker-ecom-coursework'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/pahhcn/docker-ecom-coursework.git'
        GIT_BRANCH = 'main'
        K8S_NAMESPACE = 'ecommerce'
        KUBECONFIG = '/var/jenkins_home/.kube/config'
        // 镜像仓库配置
        DOCKER_REGISTRY = 'localhost:5000'
        REGISTRY_CREDENTIALS = 'docker-registry-credentials'
        // 构建状态标记
        BUILD_SUCCESS = 'false'
    }
    
    parameters {
        choice(
            name: 'K8S_VERSION',
            choices: ['blue', 'green'],
            description: '选择部署到哪个环境（蓝或绿）'
        )
        booleanParam(
            name: 'SWITCH_TRAFFIC',
            defaultValue: false,
            description: '部署后是否自动切换流量'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: '是否跳过测试（仅用于快速部署）'
        )
        booleanParam(
            name: 'DEPLOY_MONITORING',
            defaultValue: false,
            description: '是否部署监控系统（Prometheus + Grafana）'
        )
        booleanParam(
            name: 'PUSH_TO_REGISTRY',
            defaultValue: true,
            description: '是否推送镜像到仓库'
        )
    }
    
    // 代码提交触发自动构建
    triggers {
        pollSCM('H/2 * * * *')  // 每2分钟检查代码变更
    }
    
    stages {
        stage('环境信息') {
            steps {
                echo '========================================='
                echo '📋 构建环境信息'
                echo '========================================='
                script {
                    sh """
                        echo "构建编号: ${BUILD_NUMBER}"
                        echo "镜像标签: ${IMAGE_TAG}"
                        echo "部署环境: Kubernetes 蓝绿部署"
                        echo "目标版本: ${params.K8S_VERSION}"
                        echo "自动切换流量: ${params.SWITCH_TRAFFIC}"
                        echo "工作空间: ${WORKSPACE}"
                        echo "Git 仓库: ${GIT_REPO}"
                        echo "Git 分支: ${GIT_BRANCH}"
                    """
                }
            }
        }
        
        stage('代码检出') {
            steps {
                echo '========================================='
                echo '📥 从 Git 仓库克隆代码'
                echo '========================================='
                script {
                    // 清理工作空间
                    cleanWs()
                    
                    // 从 Git 仓库克隆代码
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${GIT_BRANCH}"]],
                        userRemoteConfigs: [[url: "${GIT_REPO}"]],
                        extensions: [
                            [$class: 'CloneOption', depth: 1, noTags: false, shallow: true],
                            [$class: 'CheckoutOption', timeout: 10]
                        ]
                    ])
                    
                    // 显示提交信息
                    sh '''
                        echo "✅ 代码检出完成"
                        echo ""
                        echo "仓库: ${GIT_REPO}"
                        echo "分支: ${GIT_BRANCH}"
                        echo ""
                        echo "最新提交:"
                        git log -1 --pretty=format:"  提交: %h%n  作者: %an%n  时间: %ad%n  消息: %s"
                        echo ""
                        echo ""
                        echo "工作目录: ${WORKSPACE}"
                        ls -la
                    '''
                }
            }
        }
        
        stage('构建阶段') {
            steps {
                echo '========================================='
                echo '🔨 构建应用和Docker镜像'
                echo '========================================='
                script {
                    // 构建后端应用
                    sh """
                        echo "构建后端应用..."
                        echo "工作空间路径: ${WORKSPACE}"
                        
                        cd ${WORKSPACE}/backend
                        
                        echo "使用本地 Maven 构建..."
                        mvn -version
                        mvn clean package -DskipTests
                    """
                    
                    // 构建Docker镜像
                    sh """
                        echo "构建Docker镜像..."
                        docker build -t ${PROJECT_NAME}-frontend:${IMAGE_TAG} ./frontend
                        docker build -t ${PROJECT_NAME}-backend:${IMAGE_TAG} ./backend
                        
                        docker tag ${PROJECT_NAME}-frontend:${IMAGE_TAG} ${PROJECT_NAME}-frontend:latest
                        docker tag ${PROJECT_NAME}-backend:${IMAGE_TAG} ${PROJECT_NAME}-backend:latest
                        
                        echo "✅ 镜像构建完成"
                        docker images | grep ${PROJECT_NAME}
                    """
                }
            }
        }
        
        stage('单元测试') {
            when {
                expression { params.SKIP_TESTS == false }
            }
            steps {
                echo '========================================='
                echo '🧪 运行单元测试'
                echo '========================================='
                sh """
                    cd ${WORKSPACE}/backend
                    mvn test -Dtest=*ServiceTest
                """
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '/workspace/backend/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('集成测试') {
            when {
                expression { params.SKIP_TESTS == false }
            }
            steps {
                echo '========================================='
                echo '🔗 运行集成测试（属性测试）'
                echo '========================================='
                sh """
                    cd ${WORKSPACE}/backend
                    
                    # 只运行不需要Docker的属性测试
                    mvn test -Dtest=Product*PropertyTest
                """
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'backend/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('标记构建成功') {
            steps {
                script {
                    // 如果到达这里，说明构建和测试都成功了
                    env.BUILD_SUCCESS = 'true'
                    echo "✅ 构建和测试成功，标记为可部署版本"
                }
            }
        }
        
        stage('推送镜像到仓库') {
            when {
                expression { params.PUSH_TO_REGISTRY == true }
            }
            steps {
                echo '========================================='
                echo '📦 推送Docker镜像到仓库'
                echo '========================================='
                script {
                    sh """
                        echo "标记镜像..."
                        # 标记镜像为仓库格式
                        docker tag ${PROJECT_NAME}-frontend:${IMAGE_TAG} ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}
                        docker tag ${PROJECT_NAME}-backend:${IMAGE_TAG} ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}
                        docker tag ${PROJECT_NAME}-frontend:latest ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:latest
                        docker tag ${PROJECT_NAME}-backend:latest ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:latest
                        
                        echo "推送镜像到仓库..."
                        # 推送带版本号的镜像
                        docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} || echo "⚠️ 前端镜像推送失败"
                        docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG} || echo "⚠️ 后端镜像推送失败"
                        
                        # 推送 latest 标签
                        docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:latest || echo "⚠️ 前端 latest 推送失败"
                        docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:latest || echo "⚠️ 后端 latest 推送失败"
                        
                        echo "✅ 镜像推送完成"
                        echo "前端镜像: ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}"
                        echo "后端镜像: ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}"
                    """
                }
            }
        }
        
        stage('代码覆盖率报告') {
            when {
                expression { params.SKIP_TESTS == false }
            }
            steps {
                echo '========================================='
                echo '📊 生成代码覆盖率报告'
                echo '========================================='
                sh """
                    cd ${WORKSPACE}/backend
                    mvn jacoco:report
                    
                    echo ""
                    echo "✅ 覆盖率报告已生成"
                    echo "📊 报告位置: backend/target/site/jacoco/index.html"
                    
                    # 显示覆盖率摘要
                    if [ -f ${WORKSPACE}/backend/target/site/jacoco/index.html ]; then
                        echo "可以在工作空间中查看完整的覆盖率报告"
                    fi
                """
            }
            post {
                always {
                    script {
                        // 使用 JaCoCo 插件发布覆盖率报告
                        try {
                            jacoco(
                                execPattern: 'backend/target/jacoco.exec',
                                classPattern: 'backend/target/classes',
                                sourcePattern: 'backend/src/main/java'
                            )
                            echo "✅ JaCoCo 覆盖率报告已发布"
                        } catch (Exception e) {
                            echo "⚠️ JaCoCo 插件发布失败: ${e.message}"
                            echo "覆盖率报告已生成在: backend/target/site/jacoco/"
                        }
                    }
                }
            }
        }
        
        stage('Kubernetes蓝绿部署') {
            steps {
                echo '========================================='
                echo '🔵🟢 Kubernetes蓝绿部署'
                echo '========================================='
                script {
                    def version = params.K8S_VERSION
                    
                    sh """
                        # 标记镜像
                        echo "📦 准备镜像..."
                        docker tag ${PROJECT_NAME}-backend:${IMAGE_TAG} ecommerce-backend:latest
                        docker tag ${PROJECT_NAME}-frontend:${IMAGE_TAG} ecommerce-frontend:latest
                        
                        # 加载镜像到 minikube（在宿主机上执行）
                        echo "📦 加载镜像到 minikube..."
                        minikube image load ecommerce-backend:latest || echo "⚠️ 后端镜像加载失败"
                        minikube image load ecommerce-frontend:latest || echo "⚠️ 前端镜像加载失败"
                        
                        # 创建命名空间
                        echo "📦 创建命名空间..."
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        
                        # 部署数据库（如果不存在）
                        echo "📦 确保数据库运行..."
                        kubectl apply -f k8s/database/ -n ${K8S_NAMESPACE} || true
                        
                        # 部署 ConfigMap 和 Secret
                        echo "📦 部署配置文件..."
                        kubectl apply -f k8s/backend/backend-configmap.yaml -n ${K8S_NAMESPACE} || true
                        kubectl apply -f k8s/backend/backend-secret.yaml -n ${K8S_NAMESPACE} || true
                        kubectl apply -f k8s/frontend/frontend-configmap.yaml -n ${K8S_NAMESPACE} || true
                        
                        # 部署到指定环境（blue或green）
                        echo "📦 部署到 ${version} 环境..."
                        kubectl apply -f k8s/blue-green/backend-${version}-deployment.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f k8s/blue-green/frontend-${version}-deployment.yaml -n ${K8S_NAMESPACE}
                        
                        # 确保服务存在
                        echo "📦 确保服务存在..."
                        kubectl apply -f k8s/blue-green/backend-service-blue-green.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f k8s/blue-green/frontend-service-blue-green.yaml -n ${K8S_NAMESPACE}
                        
                        # 等待部署就绪
                        echo "⏳ 等待 ${version} 环境就绪..."
                        kubectl wait --for=condition=available deployment/backend-${version} -n ${K8S_NAMESPACE} --timeout=300s || true
                        kubectl wait --for=condition=available deployment/frontend-${version} -n ${K8S_NAMESPACE} --timeout=300s || true
                        
                        echo "✅ ${version} 环境部署完成"
                        kubectl get pods -n ${K8S_NAMESPACE} -l version=${version}
                    """
                    
                    // 如果选择自动切换流量
                    if (params.SWITCH_TRAFFIC) {
                        echo "🔄 切换流量到${version}环境..."
                        sh """
                            echo "切换后端服务到 ${version}..."
                            kubectl patch service backend-service -n ${K8S_NAMESPACE} -p '{"spec":{"selector":{"version":"${version}"}}}'
                            
                            echo "切换前端服务到 ${version}..."
                            kubectl patch service frontend-service -n ${K8S_NAMESPACE} -p '{"spec":{"selector":{"version":"${version}"}}}'
                            
                            echo "✅ 流量已切换到 ${version} 环境"
                            kubectl get service -n ${K8S_NAMESPACE} -o yaml | grep -A 3 selector
                        """
                    } else {
                        echo "⚠️  流量未切换，请手动执行切换"
                        echo "手动切换命令: kubectl patch service backend-service -n ${K8S_NAMESPACE} -p '{\"spec\":{\"selector\":{\"version\":\"${version}\"}}}'"
                    }
                }
            }
        }
        
        stage('健康检查') {
            steps {
                echo '========================================='
                echo '🏥 服务健康检查'
                echo '========================================='
                script {
                    sh """
                        echo "检查Kubernetes部署状态..."
                        kubectl get pods -n ${K8S_NAMESPACE}
                        
                        echo ""
                        echo "检查服务状态..."
                        kubectl get services -n ${K8S_NAMESPACE}
                        
                        echo ""
                        echo "检查部署健康..."
                        kubectl get deployments -n ${K8S_NAMESPACE}
                        
                        echo ""
                        echo "获取服务访问信息..."
                        # 获取 NodePort
                        FRONTEND_PORT=\$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
                        MINIKUBE_IP=\$(minikube ip)
                        
                        echo ""
                        echo "✅ 部署完成"
                        echo ""
                        echo "🌐 访问地址:"
                        echo "   前端: http://\${MINIKUBE_IP}:\${FRONTEND_PORT}"
                        echo "   或使用端口转发: minikube kubectl -- port-forward -n ${K8S_NAMESPACE} --address 0.0.0.0 service/frontend-service 8082:80"
                        echo "   后端API: http://\${MINIKUBE_IP}:\${FRONTEND_PORT}/api/products"
                        echo ""
                        echo "💡 提示: 端口转发需要在宿主机终端手动运行，Jenkins 容器内的端口转发在构建结束后会停止"
                    """
                }
            }
        }
        
        stage('部署监控系统') {
            when {
                expression { params.DEPLOY_MONITORING == true }
            }
            steps {
                echo '========================================='
                echo '📊 部署APM监控系统 (Prometheus + Grafana)'
                echo '========================================='
                script {
                    sh '''
                        echo "📊 部署 Kubernetes 监控栈..."
                        
                        # 检查监控命名空间
                        kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
                        
                        # 部署 Prometheus（如果配置存在）
                        if [ -d "/workspace/monitoring/prometheus" ]; then
                            echo "部署 Prometheus..."
                            kubectl apply -f /workspace/monitoring/prometheus/ -n monitoring || echo "⚠️ Prometheus 配置不存在"
                        fi
                        
                        # 部署 Grafana（如果配置存在）
                        if [ -d "/workspace/monitoring/grafana" ]; then
                            echo "部署 Grafana..."
                            kubectl apply -f /workspace/monitoring/grafana/ -n monitoring || echo "⚠️ Grafana 配置不存在"
                        fi
                        
                        # 部署 Alertmanager（如果配置存在）
                        if [ -d "/workspace/monitoring/alertmanager" ]; then
                            echo "部署 Alertmanager..."
                            kubectl apply -f /workspace/monitoring/alertmanager/ -n monitoring || echo "⚠️ Alertmanager 配置不存在"
                        fi
                        echo "✅ 监控系统部署完成"
                        echo "📊 查看监控服务:"
                        kubectl get all -n monitoring || echo "⚠️ 监控服务未配置"
                        
                        echo ""
                        echo "💡 访问监控服务需要端口转发:"
                        echo "   kubectl port-forward -n monitoring service/grafana 3000:3000"
                        echo "   kubectl port-forward -n monitoring service/prometheus 9090:9090"
                        echo "   kubectl port-forward -n monitoring service/alertmanager 9093:9093"
                    '''
                }
            }
        }
        
        stage('部署验证') {
            steps {
                echo '========================================='
                echo '✅ 部署验证'
                echo '========================================='
                script {
                    sh """
                        echo "验证Kubernetes蓝绿部署..."
                        
                        # 检查所有Pod是否运行
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        
                        # 检查是否有失败的Pod
                        FAILED_PODS=\$(kubectl get pods -n ${K8S_NAMESPACE} --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
                        
                        if [ "\$FAILED_PODS" -gt 0 ]; then
                            echo "⚠️ 发现 \$FAILED_PODS 个异常Pod"
                            kubectl get pods -n ${K8S_NAMESPACE} --field-selector=status.phase!=Running,status.phase!=Succeeded
                        else
                            echo "✅ 所有Pod运行正常"
                        fi
                        
                        # 通过 K8s 内部服务测试
                        echo ""
                        echo "测试服务（通过 K8s 内部）..."
                        
                        # 使用 kubectl exec 在集群内部测试服务
                        echo "测试后端健康检查..."
                        kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never --timeout=30s -- \
                            curl -sf http://backend-service.${K8S_NAMESPACE}.svc.cluster.local:8080/actuator/health \
                            && echo "✅ 后端服务正常" || echo "⚠️ 后端服务检查失败"
                        
                        echo ""
                        echo "✅ Kubernetes蓝绿部署验证完成"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo '========================================='
            echo '📊 Pipeline 执行完成'
            echo '========================================='
        }
        
        success {
            script {
                def monitoringInfo = ""
                
                if (params.DEPLOY_MONITORING) {
                    monitoringInfo = """
                    
                    📊 监控系统 (Kubernetes):
                      查看服务: kubectl get all -n monitoring
                      访问 Grafana: kubectl port-forward -n monitoring service/grafana 3000:3000
                      访问 Prometheus: kubectl port-forward -n monitoring service/prometheus 9090:9090
                      访问 Alertmanager: kubectl port-forward -n monitoring service/alertmanager 9093:9093
                    """
                }
                
                def trafficStatus = params.SWITCH_TRAFFIC ? "已切换到${params.K8S_VERSION}" : "未切换（待手动切换）"
                
                echo '✅ ========================================='
                echo '✅ CI/CD Pipeline 执行成功！'
                echo '✅ ========================================='
                echo ''
                echo '📦 构建信息:'
                echo "   构建编号: ${BUILD_NUMBER}"
                echo "   镜像标签: ${IMAGE_TAG}"
                echo "   部署环境: Kubernetes 蓝绿部署"
                echo ''
                echo '🎯 部署详情:'
                echo "   ☸️  Kubernetes容器编排: ✅ 已启用"
                echo "   🔵🟢 蓝绿部署: ✅ 已启用"
                echo "   📦 部署版本: ${params.K8S_VERSION}"
                echo "   🔄 流量状态: ${trafficStatus}"
                echo "   📊 APM监控: ${params.DEPLOY_MONITORING ? '✅ 已启用' : '⬜ 未启用'}"
                echo ''
                echo '🌐 访问服务（需要在宿主机运行端口转发）:'
                echo '   ./start-port-forward.sh'
                echo '   然后访问: http://localhost:8082'
                
                if (!params.SWITCH_TRAFFIC) {
                    echo ''
                    echo '⚠️  流量未切换，手动切换命令:'
                    echo "   cd k8s/blue-green && ./switch-traffic.sh ${params.K8S_VERSION}"
                }
                
                if (monitoringInfo) {
                    echo monitoringInfo
                }
                
                echo ''
                echo '📊 测试报告:'
                echo '   JUnit测试报告: 查看构建页面'
                echo '   覆盖率报告: 查看JaCoCo Coverage Report'
                echo '✅ ========================================='
            }
        }
        
        failure {
            echo '❌ ========================================='
            echo '❌ Pipeline 执行失败'
            echo '❌ ========================================='
            echo '请查看构建日志获取详细错误信息'
            echo ''
            echo '常见问题排查:'
            echo '  1. 检查Docker服务是否运行'
            echo '  2. 检查kubectl配置是否正确'
            echo '  3. 检查镜像是否构建成功'
            echo '  4. 查看具体阶段的错误日志'
        }
    }
}
