pipeline {
    agent {
        docker {
            image 'docker:latest'
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    environment {
        DOCKER_IMAGE = "market-app:${BUILD_NUMBER}"
        KUBE_NAMESPACE = "market"
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    apk add --no-cache curl git bash
                    echo "🔧 Setup completed"
                '''
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }
        
        stage('Install Minikube & kubectl') {
            steps {
                sh '''
                    echo "📦 Installing Minikube and kubectl..."
                    
                    # Устанавливаем kubectl
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    chmod +x kubectl
                    mv kubectl /usr/local/bin/
                    
                    # Устанавливаем Minikube
                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                    install minikube-linux-amd64 /usr/local/bin/minikube
                    
                    # Проверяем установку
                    kubectl version --client
                    minikube version
                '''
            }
        }
        
        stage('Start Minikube') {
            steps {
                sh '''
                    echo "🚀 Starting Minikube..."
                    minikube start --driver=docker --memory=4096 --cpus=2
                    minikube status
                    
                    # Настраиваем Docker окружение
                    eval $(minikube docker-env)
                    docker ps
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "🏗️ Building Docker image..."
                    docker build -t ${DOCKER_IMAGE} .
                    docker tag ${DOCKER_IMAGE} market-app:latest
                    docker images | grep market-app
                '''
            }
        }
        
        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Deploying application..."
                    
                    # Создаем namespace если нет
                    kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Запускаем скрипт деплоя
                    chmod +x deploy-app-only.sh
                    ./deploy-app-only.sh
                    
                    # Или деплоим напрямую
                    kubectl apply -f k8s/ || echo "No k8s directory, using inline deployment"
                '''
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Verifying deployment..."
                    sleep 10
                    
                    kubectl get all -n ${KUBE_NAMESPACE}
                    kubectl logs -n ${KUBE_NAMESPACE} -l app=market-app --tail=10
                '''
            }
        }
    }
    
    post {
        always {
            sh '''
                echo "🧹 Cleaning up..."
                minikube stop || true
            '''
        }
    }
}