pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        
        stage('Install Required Tools') {
            steps {
                sh '''
                    echo "📦 Устанавливаю необходимые инструменты..."
                    
                    # Проверяем и устанавливаем kubectl если нет
                    if ! command -v kubectl &> /dev/null; then
                        echo "Устанавливаю kubectl..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/
                        echo "✅ kubectl установлен"
                    else
                        echo "✅ kubectl уже установлен"
                        kubectl version --client
                    fi
                    
                    # Проверяем Docker
                    if command -v docker &> /dev/null; then
                        echo "✅ Docker доступен"
                        docker --version
                    else
                        echo "⚠️ Docker не доступен"
                    fi
                '''
            }
        }
        
        stage('Generate Deployment Instructions') {
            steps {
                sh '''
                    echo "📋 ГЕНЕРИРУЮ ИНСТРУКЦИИ ДЛЯ ДЕПЛОЯ"
                    echo "=================================="
                    
                    cat > DEPLOYMENT_INSTRUCTIONS.md << EOF
                    # Инструкции для деплоя Market App
                    
                    ## Текущая сборка
                    - Номер: ${BUILD_NUMBER}
                    - Дата: $(date)
                    - Репозиторий: ${GIT_URL}
                    
                    ## Проблема
                    Jenkins не имеет доступа к Minikube/kubectl.
                    
                    ## Решение 1: Установить kubectl в Jenkins
                    \`\`\`bash
                    # Войдите в Jenkins контейнер
                    docker exec -it -u root jenkins_container bash
                    
                    # Установите kubectl
                    curl -LO "https://dl.k8s.io/release/\\\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                    \`\`\`
                    
                    ## Решение 2: Запустить деплой вручную
                    
                    ### На машине с Minikube выполните:
                    
                    1. **Клонируйте репозиторий** (если еще не):
                    \`\`\`bash
                    git clone https://github.com/alexsanderknyazev-ops/shop.git
                    cd shop
                    \`\`\`
                    
                    2. **Разверните PostgreSQL**:
                    \`\`\`bash
                    chmod +x final-postgres.sh
                    ./final-postgres.sh
                    \`\`\`
                    
                    3. **Разверните приложение**:
                    \`\`\`bash
                    chmod +x deploy-app-only.sh
                    ./deploy-app-only.sh
                    \`\`\`
                    
                    4. **Проверьте статус**:
                    \`\`\`bash
                    kubectl get pods -n market
                    kubectl get svc -n market
                    \`\`\`
                    
                    5. **Доступ к приложению**:
                    \`\`\`bash
                    kubectl port-forward -n market svc/market-service 8070:8070
                    # Откройте: http://localhost:8070
                    \`\`\`
                    
                    ## Решение 3: Использовать SSH деплой
                    
                    Настройте SSH доступ с Jenkins на машину с Minikube.
                    
                    EOF
                    
                    echo "✅ Инструкции сохранены в DEPLOYMENT_INSTRUCTIONS.md"
                    cat DEPLOYMENT_INSTRUCTIONS.md
                '''
            }
        }
        
        stage('Test Scripts') {
            steps {
                sh '''
                    echo "🧪 Тестирую скрипты..."
                    
                    # Проверяем синтаксис скриптов
                    for script in *.sh; do
                        if [ -f "$script" ]; then
                            echo "Проверяю: $script"
                            chmod +x "$script"
                            # Показываем первые 5 строк
                            head -5 "$script"
                            echo ""
                        fi
                    done
                    
                    echo "✅ Тестирование завершено"
                '''
            }
        }
    }
    
    post {
        success {
            echo "✅ Jenkins сборка успешна!"
            echo ""
            echo "🔧 Деплой должен быть выполнен ВРУЧНУЮ на машине с Minikube:"
            echo "   ./final-postgres.sh && ./deploy-app-only.sh"
            echo ""
            echo "📁 Инструкции сохранены в DEPLOYMENT_INSTRUCTIONS.md"
            archiveArtifacts artifacts: 'DEPLOYMENT_INSTRUCTIONS.md, *.sh', fingerprint: true
        }
    }
}