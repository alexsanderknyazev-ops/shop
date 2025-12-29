#!/bin/bash
set -e  # Выход при ошибке

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} ERROR: $1"
    exit 1
}

# Переменные
NAMESPACE="market"
IMAGE_TAG="${DOCKER_IMAGE:-market-app:latest}"
TIMEOUT=180

log "========================================"
log "🚀 MARKET APP DEPLOYMENT"
log "========================================"

# 1. Устанавливаем namespace
log "1. Setting up namespace..."
kubectl apply -f k8s/00-namespace.yaml

# 2. Развертываем PostgreSQL (если нужно)
log "2. Deploying PostgreSQL..."
kubectl apply -n $NAMESPACE -f k8s/10-postgres-configmap.yaml
kubectl apply -n $NAMESPACE -f k8s/11-postgres-secret.yaml
kubectl apply -n $NAMESPACE -f k8s/12-postgres-pvc.yaml
kubectl apply -n $NAMESPACE -f k8s/13-postgres-deployment.yaml
kubectl apply -n $NAMESPACE -f k8s/14-postgres-service.yaml

# Ждем PostgreSQL
log "   Waiting for PostgreSQL to be ready..."
if kubectl wait --for=condition=ready pod -n $NAMESPACE -l app=postgres --timeout=${TIMEOUT}s 2>/dev/null; then
    log "   ✅ PostgreSQL is ready"
else
    log "   ⚠️ PostgreSQL not ready, but continuing..."
fi

# 3. Запускаем миграции (если есть)
if [ -f "k8s/15-migration-job.yaml" ]; then
    log "3. Running database migrations..."
    kubectl apply -n $NAMESPACE -f k8s/15-migration-job.yaml
    sleep 10
fi

# 4. Обновляем ConfigMap и Secret для приложения
log "4. Applying application configuration..."
kubectl apply -n $NAMESPACE -f k8s/01-configmap.yaml
kubectl apply -n $NAMESPACE -f k8s/02-secrets.yaml

# 5. Обновляем образ в deployment
log "5. Updating application image to: $IMAGE_TAG"
# Создаем временный файл deployment с обновленным образом
cat k8s/03-deployment.yaml | sed "s|image:.*|image: $IMAGE_TAG|" | kubectl apply -n $NAMESPACE -f -

# 6. Развертываем остальные ресурсы
log "6. Deploying services..."
kubectl apply -n $NAMESPACE -f k8s/04-service.yaml

# Применяем HPA если есть
if [ -f "k8s/05-hpa.yaml" ]; then
    kubectl apply -n $NAMESPACE -f k8s/05-hpa.yaml
fi

# Применяем Ingress если есть
if [ -f "k8s/06-ingress.yaml" ]; then
    kubectl apply -n $NAMESPACE -f k8s/06-ingress.yaml
fi

# 7. Ждем развертывания приложения
log "7. Waiting for application rollout..."
if kubectl rollout status deployment/market-deployment -n $NAMESPACE --timeout=${TIMEOUT}s; then
    log "   ✅ Application deployed successfully"
else
    error "Application deployment failed!"
fi

# 8. Проверка статуса
log "8. Checking deployment status..."
echo ""
echo "📊 PODS:"
kubectl get pods -n $NAMESPACE -o wide
echo ""
echo "📊 SERVICES:"
kubectl get svc -n $NAMESPACE
echo ""
echo "📊 DEPLOYMENTS:"
kubectl get deployments -n $NAMESPACE

# 9. Проверка health endpoint
log "9. Testing application health..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=market -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    log "   Forwarding port 8070..."
    kubectl port-forward -n $NAMESPACE pod/$POD_NAME 8070:8070 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 5
    
    if curl -s http://localhost:8070/inventory/health > /dev/null 2>&1; then
        log "   ✅ Health check passed"
    else
        log "   ⚠️ Health check failed (but deployment succeeded)"
    fi
    
    kill $PF_PID 2>/dev/null
fi

log "========================================"
log "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
log "========================================"
log ""
log "📌 Application URL: http://market-service.market:8070"
log "📌 PostgreSQL: postgres.market:5432"
log ""
log "🔧 Useful commands:"
log "   kubectl logs -n market -l app=market -f"
log "   kubectl describe deployment -n market market-deployment"
log "   kubectl get all -n market"
log ""