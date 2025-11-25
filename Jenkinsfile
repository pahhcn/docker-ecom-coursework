pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = credentials('docker-registry-url')
        DOCKER_CREDENTIALS = credentials('docker-credentials-id')
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }
    
    triggers {
        // Trigger on push to main branch
        pollSCM('H/5 * * * *')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Build Backend') {
            agent {
                docker {
                    image 'maven:3.9-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                dir('backend') {
                    sh 'mvn clean package -DskipTests'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'backend/target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    // Build frontend image
                    docker.build(
                        "ecommerce/frontend:${IMAGE_TAG}",
                        "./frontend"
                    )
                    docker.build(
                        "ecommerce/frontend:latest",
                        "./frontend"
                    )
                    
                    // Build backend image
                    docker.build(
                        "ecommerce/backend:${IMAGE_TAG}",
                        "./backend"
                    )
                    docker.build(
                        "ecommerce/backend:latest",
                        "./backend"
                    )
                    
                    // Build database image if Dockerfile exists
                    if (fileExists('database/Dockerfile')) {
                        docker.build(
                            "ecommerce/database:${IMAGE_TAG}",
                            "./database"
                        )
                        docker.build(
                            "ecommerce/database:latest",
                            "./database"
                        )
                    }
                }
            }
        }
        
        stage('Run Unit Tests') {
            agent {
                docker {
                    image 'maven:3.9-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2 -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                dir('backend') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit 'backend/target/surefire-reports/*.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'backend/target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'JaCoCo Coverage Report'
                    ])
                    jacoco(
                        execPattern: 'backend/target/jacoco.exec',
                        classPattern: 'backend/target/classes',
                        sourcePattern: 'backend/src/main/java',
                        exclusionPattern: '**/*Test*.class'
                    )
                }
            }
        }
        
        stage('Run Integration Tests') {
            agent {
                docker {
                    image 'maven:3.9-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2 -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                dir('backend') {
                    sh 'mvn verify -Dtest=*IntegrationTest,*PropertyTest'
                }
            }
            post {
                always {
                    junit 'backend/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Code Coverage Check') {
            agent {
                docker {
                    image 'maven:3.9-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                dir('backend') {
                    sh 'mvn jacoco:check'
                }
            }
        }
        
        stage('Push Images to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS}") {
                        // Push frontend images
                        docker.image("ecommerce/frontend:${IMAGE_TAG}").push()
                        
                        // Push backend images
                        docker.image("ecommerce/backend:${IMAGE_TAG}").push()
                        
                        // Push latest tag only for main branch
                        if (env.BRANCH_NAME == 'main') {
                            docker.image("ecommerce/frontend:latest").push()
                            docker.image("ecommerce/backend:latest").push()
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                input message: 'Deploy to staging?', ok: 'Deploy'
                script {
                    sh '''
                        docker-compose -f docker-compose.yml pull
                        docker-compose -f docker-compose.yml up -d
                        sleep 30
                        docker-compose -f docker-compose.yml ps
                    '''
                    
                    // Run smoke tests
                    sh '''
                        echo "Running smoke tests..."
                        curl -f http://localhost:80 || exit 1
                        curl -f http://localhost:8080/actuator/health || exit 1
                        echo "Smoke tests passed!"
                    '''
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                script {
                    sh '''
                        docker-compose -f docker-compose.yml pull
                        docker-compose -f docker-compose.yml up -d
                        sleep 30
                        docker-compose -f docker-compose.yml ps
                    '''
                    
                    // Run smoke tests
                    sh '''
                        echo "Running smoke tests..."
                        curl -f http://localhost:80 || exit 1
                        curl -f http://localhost:8080/actuator/health || exit 1
                        echo "Smoke tests passed!"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images to save space
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline completed successfully!'
            // Send success notification
            script {
                if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop') {
                    // Example: Send Slack notification
                    // slackSend(
                    //     color: 'good',
                    //     message: "Build ${env.BUILD_NUMBER} succeeded for ${env.BRANCH_NAME}"
                    // )
                    echo 'Success notification sent (configure Slack/email in Jenkins)'
                }
            }
        }
        failure {
            echo 'Pipeline failed!'
            // Send failure notification
            script {
                // Example: Send Slack notification
                // slackSend(
                //     color: 'danger',
                //     message: "Build ${env.BUILD_NUMBER} failed for ${env.BRANCH_NAME}"
                // )
                echo 'Failure notification sent (configure Slack/email in Jenkins)'
            }
        }
        unstable {
            echo 'Pipeline is unstable!'
            // Send unstable notification
            script {
                echo 'Unstable notification sent (configure Slack/email in Jenkins)'
            }
        }
    }
}
