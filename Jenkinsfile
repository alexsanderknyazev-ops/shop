pipeline {
    agent any
    
    environment {
        // Варианты подключения к вашему Mac:
        // 1. Если Jenkins в Docker на том же Mac:
        // DEPLOY_SERVER = 'host.docker.internal'
        
        // 2. Если Jenkins установлен напрямую на Mac:
        // DEPLOY_SERVER = 'localhost'
        
        // 3. Если Jenkins на другой машине в сети:
        // DEPLOY_SERVER = '192.168.0.30'
        
        DEPLOY_SERVER = 'host.docker.internal'  // Начните с этого
        DEPLOY_USER = 'aleksandrknazev'
        BUILD_DIR = "/tmp/jenkins-build-${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout & Setup') {
            steps {
                checkout scm
                sh '''
                    echo "🔧 Jenkins Build: ${BUILD_NUMBER}"
                    echo "📦 Deploy to: ${DEPLOY_SERVER}"
                    echo "👤 User: ${DEPLOY_USER}"
                    ls -la
                '''
            }
        }
        
        stage('Test Connection') {
            steps {
                sshagent(['minikube-server']) {
                    sh """
                        echo "🔍 Testing connection to ${DEPLOY_SERVER}..."
                        
                        # Тест SSH подключения
                        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
                            ${DEPLOY_USER}@${DEPLOY_SERVER} "echo '✅ SSH test successful'"; then
                            echo "SSH connection OK"
                        else
                            echo "⚠️ SSH failed, trying alternative methods..."
                            
                            # Попробуем проверить доступ другими способами
                            echo "Testing if Jenkins has direct access to Minikube..."
                            if command -v minikube &> /dev/null; then
                                echo "Minikube found on Jenkins host"
                            else
                                echo "Minikube not found on Jenkins"
                            fi
                        fi
                    """
                }
            }
        }
        
        stage('Prepare Deployment') {
            steps {
                sshagent(['minikube-server']) {
                    sh """
                        echo "📋 Preparing deployment on ${DEPLOY_SERVER}..."
                        
                        # 1. Проверяем что на удаленной машине есть Minikube
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} "
                            echo '=== System Check ==='
                            
                            # Проверяем Minikube
                            if command -v minikube &> /dev/null; then
                                echo 'Minikube: ✓'
                                minikube status || echo 'Minikube not running'
                            else
                                echo '❌ Minikube not installed'
                                echo 'Install with: brew install minikube'
                                exit 1
                            fi
                            
                            # Проверяем kubectl
                            if command -v kubectl &> /dev/null; then
                                echo 'kubectl: ✓'
                            else
                                echo '❌ kubectl not installed'
                                exit 1
                            fi
                            
                            # Проверяем Docker
                            if command -v docker &> /dev/null; then
                                echo 'Docker: ✓'
                            else
                                echo '❌ Docker not installed'
                                exit 1
                            fi
                        "
                        
                        # 2. Создаем директорию для сборки
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} "
                            mkdir -p ${BUILD_DIR}
                            echo 'Build directory: ${BUILD_DIR}'
                        "
                    """
                }
            }
        }
        
        stage('Copy Source Code') {
            steps {
                sshagent(['minikube-server']) {
                    sh """
                        echo "📦 Copying source code..."
                        
                        # Создаем архив и копируем
                        tar --exclude='.git' -czf - . | \
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} \
                            "tar xzf - -C ${BUILD_DIR}"
                        
                        echo "✅ Source code copied"
                    """
                }
            }
        }
        
        stage('Build and Deploy') {
            steps {
                sshagent(['minikube-server']) {
                    sh """
                        echo "🚀 Building and deploying..."
                        
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} "
                            set -e
                            cd ${BUILD_DIR}
                            
                            echo '=== Step 1: Start Minikube ==='
                            if ! minikube status | grep -q 'Running'; then
                                echo 'Starting Minikube...'
                                minikube start --memory=4096 --cpus=2
                            else
                                echo 'Minikube already running'
                            fi
                            
                            echo '=== Step 2: Setup Docker ==='
                            eval \$(minikube docker-env)
                            echo 'Docker environment configured'
                            
                            echo '=== Step 3: Build Docker Image ==='
                            docker build -t market-app:${BUILD_NUMBER} .
                            docker tag market-app:${BUILD_NUMBER} market-app:latest
                            echo 'Docker image built'
                            
                            echo '=== Step 4: Deploy Application ==='
                            chmod +x deploy-app-only.sh
                            ./deploy-app-only.sh
                            
                            echo '✅ Build and deploy completed'
                        "
                    """
                }
            }
        }
        
        stage('Verify and Test') {
            steps {
                sshagent(['minikube-server']) {
                    sh """
                        echo "🔍 Verifying deployment..."
                        
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} "
                            echo '=== Deployment Status ==='
                            
                            # Даем приложению время на запуск
                            sleep 15
                            
                            # 1. Проверяем ресурсы
                            echo '--- Kubernetes Resources ---'
                            kubectl get pods,svc,deploy -n market
                            
                            # 2. Проверяем логи
                            echo '--- Application Logs ---'
                            kubectl logs -n market -l app=market-app --tail=10 2>/dev/null || echo 'Logs not available yet'
                            
                            # 3. Health check через port-forward
                            echo '--- Health Check ---'
                            timeout 15 bash -c '
                                kubectl port-forward -n market svc/market-service 8070:8070 &
                                PF_PID=\\\$!
                                sleep 5
                                
                                if curl -s --max-time 10 http://localhost:8070/inventory/health > /dev/null; then
                                    echo \"✅ Health check PASSED\"
                                    curl -s http://localhost:8070/inventory/health | head -c 100
                                    echo \"...\"
                                else
                                    echo \"⚠️ Health check FAILED\"
                                fi
                                
                                kill \\\$PF_PID 2>/dev/null
                            ' || echo 'Health check timeout'
                            
                            echo '=== Verification Complete ==='
                        "
                    """
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                sshagent(['minikube-server']) {
                    sh """
                        echo "🧹 Cleaning up temporary files..."
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_SERVER} "
                            rm -rf ${BUILD_DIR}
                            echo 'Temporary files removed'
                        "
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 🎉 🎉 DEPLOYMENT SUCCESSFUL! 🎉 🎉 🎉"
            echo ""
            echo "📋 Your Market App is now running in Minikube!"
            echo ""
            echo "🌐 To access the application:"
            echo "   1. Open terminal on your Mac"
            echo "   2. Run: kubectl port-forward -n market svc/market-service 8070:8070"
            echo "   3. Open browser: http://localhost:8070"
            echo "   4. Health check: http://localhost:8070/inventory/health"
            echo ""
            echo "🔧 Useful commands:"
            echo "   kubectl get pods -n market"
            echo "   kubectl logs -n market -l app=market-app -f"
            echo "   kubectl describe pod -n market <pod-name>"
            echo ""
            echo "🔄 Next deployment will automatically update the app!"
        }
        failure {
            echo "❌ Deployment failed!"
            echo "Check SSH connectivity and ensure Minikube is running on ${DEPLOY_SERVER}"
        }
        always {
            archiveArtifacts artifacts: '**/deploy*.sh,**/Jenkinsfile', fingerprint: true
        }
    }
}