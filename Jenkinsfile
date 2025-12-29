pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }
        
        stage('Generate Deployment Instructions') {
            steps {
                sh '''
                    echo "📋 СОЗДАЮ ИНСТРУКЦИИ ДЛЯ ДЕПЛОЯ"
                    echo "==============================="
                    
                    # Создаем файл с инструкциями
                    cat > DEPLOY_INSTRUCTIONS.txt << EOF
                    ============================================
                    ИНСТРУКЦИИ ДЛЯ ДЕПЛОЯ MARKET APP
                    ============================================
                    
                    Сборка: ${BUILD_NUMBER}
                    Дата: $(date)
                    Репозиторий: ${GIT_URL}
                    
                    Jenkins не имеет доступа к Minikube/kubectl.
                    Выполните деплой ВРУЧНУЮ на машине с Minikube.
                    
                    ШАГИ ДЛЯ ДЕПЛОЯ:
                    ----------------
                    
                    1. Клонируйте репозиторий (если еще не):
                       git clone https://github.com/alexsanderknyazev-ops/shop.git
                       cd shop
                    
                    2. Разверните PostgreSQL:
                       chmod +x final-postgres.sh
                       ./final-postgres.sh
                    
                    3. Разверните приложение:
                       chmod +x deploy-app-only.sh
                       ./deploy-app-only.sh
                    
                    4. Проверьте статус:
                       kubectl get pods -n market
                       kubectl get svc -n market
                    
                    5. Доступ к приложению:
                       kubectl port-forward -n market svc/market-service 8070:8070
                       Затем откройте: http://localhost:8070
                    
                    БЫСТРАЯ КОМАНДА:
                    ----------------
                       ./final-postgres.sh && ./deploy-app-only.sh
                    
                    ============================================
                    EOF
                    
                    echo "✅ Инструкции сохранены в DEPLOY_INSTRUCTIONS.txt"
                    echo ""
                    cat DEPLOY_INSTRUCTIONS.txt
                '''
            }
        }
        
        stage('Create Deployment Package') {
            steps {
                sh '''
                    echo "📦 СОЗДАЮ ПАКЕТ ДЛЯ ДЕПЛОЯ"
                    
                    # Создаем архив со всеми файлами для деплоя
                    tar czf deploy-package-${BUILD_NUMBER}.tar.gz \
                        *.sh \
                        Dockerfile \
                        go.mod go.sum \
                        main.go \
                        config/ database/ handler/ modules/ router/ service/ \
                        k8s/ 2>/dev/null || echo "Некоторые файлы не найдены"
                    
                    # Создаем простой скрипт для деплоя
                    cat > deploy-now.sh << 'EOF'
                    #!/bin/bash
                    echo "=== СКРИПТ ДЕПЛОЯ MARKET APP ==="
                    echo ""
                    echo "1. Распакуйте архив:"
                    echo "   tar xzf deploy-package-*.tar.gz"
                    echo ""
                    echo "2. Запустите деплой:"
                    echo "   chmod +x *.sh"
                    echo "   ./final-postgres.sh"
                    echo "   ./deploy-app-only.sh"
                    echo ""
                    echo "3. Проверьте:"
                    echo "   kubectl get pods -n market"
                    echo ""
                    echo "4. Доступ к приложению:"
                    echo "   kubectl port-forward -n market svc/market-service 8070:8070"
                    echo "   http://localhost:8070"
                    EOF
                    
                    chmod +x deploy-now.sh
                    
                    echo "✅ Созданы:"
                    echo "   - deploy-package-${BUILD_NUMBER}.tar.gz"
                    echo "   - deploy-now.sh"
                    echo "   - DEPLOY_INSTRUCTIONS.txt"
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎯 СБОРКА УСПЕШНА!"
            echo ""
            echo "📦 Файлы для деплоя готовы:"
            echo "   1. deploy-package-${BUILD_NUMBER}.tar.gz"
            echo "   2. deploy-now.sh"
            echo "   3. DEPLOY_INSTRUCTIONS.txt"
            echo ""
            echo "🚀 Для деплоя выполните на машине с Minikube:"
            echo "   ./final-postgres.sh && ./deploy-app-only.sh"
            
            // Сохраняем артефакты
            archiveArtifacts artifacts: 'deploy-package-*.tar.gz, deploy-now.sh, DEPLOY_INSTRUCTIONS.txt', fingerprint: true
        }
        failure {
            echo "❌ Сборка завершилась с ошибкой!"
        }
        always {
            sh 'echo "Сборка ${BUILD_NUMBER} завершена"'
        }
    }
}