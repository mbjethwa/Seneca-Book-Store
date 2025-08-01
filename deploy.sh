#!/bin/bash

# 🚀 Seneca Book Store - Unified Deployment Script
# This script supports both Docker Compose and Kubernetes deployments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="seneca-bookstore"
NAMESPACE="seneca-bookstore"
REGISTRY="localhost:5000"
VERSION="latest"
DOMAIN="senecabooks.local"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}   Seneca Book Store Deployment Script   ${NC}"
    echo -e "${PURPLE}========================================${NC}"
}

print_status() {
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi
    
    # Check for optional dependencies based on deployment mode
    if [ "$DEPLOYMENT_MODE" = "kubernetes" ] || [ "$DEPLOYMENT_MODE" = "both" ]; then
        if ! command_exists kubectl; then
            if [ "$DEPLOYMENT_MODE" = "kubernetes" ]; then
                missing_deps+=("kubectl")
            else
                print_warning "kubectl not found - Kubernetes deployment will be skipped"
                SKIP_K8S=true
            fi
        fi
        
        if ! command_exists minikube; then
            if [ "$DEPLOYMENT_MODE" = "kubernetes" ]; then
                missing_deps+=("minikube")
            else
                print_warning "minikube not found - Kubernetes deployment will be skipped"
                SKIP_K8S=true
            fi
        fi
    fi
    
    if ! command_exists helm; then
        print_warning "Helm not found - some Kubernetes features may be limited"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
    
    print_success "Prerequisites check completed!"
}

# Function to build Docker images
build_images() {
    print_step "Building Docker images..."
    
    # If using Kubernetes, configure Docker to use Minikube's Docker daemon
    if [ "$DEPLOYMENT_MODE" = "kubernetes" ] || [ "$DEPLOYMENT_MODE" = "both" ]; then
        if [ "$SKIP_K8S" != true ]; then
            eval $(minikube docker-env) 2>/dev/null || true
        fi
    fi
    
    local services=("user-service" "catalog-service" "order-service" "frontend-service")
    
    for service in "${services[@]}"; do
        print_status "Building $service image..."
        
        if [ -d "$service" ]; then
            cd "$service"
            docker build -t "$REGISTRY/$service:$VERSION" .
            
            # Also tag for local use
            docker tag "$REGISTRY/$service:$VERSION" "$service:$VERSION"
            
            cd ..
            print_success "$service image built successfully"
        else
            print_warning "Directory $service not found, skipping..."
        fi
    done
    
    print_success "All Docker images built successfully!"
}

# Function to create docker-compose file
create_docker_compose() {
    print_step "Creating docker-compose.yml..."
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  user-service:
    image: ${REGISTRY}/user-service:${VERSION}
    ports:
      - "8001:8000"
    environment:
      - PORT=8000
      - SECRET_KEY=your-super-secret-jwt-key-change-in-production-please
      - DATABASE_URL=sqlite:///./users.db
      - ACCESS_TOKEN_EXPIRE_MINUTES=60
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    volumes:
      - user_data:/app

  catalog-service:
    image: ${REGISTRY}/catalog-service:${VERSION}
    ports:
      - "8002:8000"
    environment:
      - PORT=8000
      - DATABASE_URL=sqlite:///./catalog.db
      - USER_SERVICE_URL=http://user-service:8000
      - ADMIN_EMAILS=admin@seneca.ca,admin@example.com
    depends_on:
      user-service:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    volumes:
      - catalog_data:/app

  order-service:
    image: ${REGISTRY}/order-service:${VERSION}
    ports:
      - "8003:8000"
    environment:
      - PORT=8000
      - DATABASE_URL=sqlite:///./orders.db
      - USER_SERVICE_URL=http://user-service:8000
      - CATALOG_SERVICE_URL=http://catalog-service:8000
    depends_on:
      user-service:
        condition: service_healthy
      catalog-service:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    volumes:
      - order_data:/app

  frontend-service:
    image: ${REGISTRY}/frontend-service:${VERSION}
    ports:
      - "3000:80"
    depends_on:
      user-service:
        condition: service_healthy
      catalog-service:
        condition: service_healthy
      order-service:
        condition: service_healthy
    environment:
      - REACT_APP_USER_SERVICE_URL=http://localhost:8001
      - REACT_APP_CATALOG_SERVICE_URL=http://localhost:8002
      - REACT_APP_ORDER_SERVICE_URL=http://localhost:8003
    restart: unless-stopped

volumes:
  user_data:
  catalog_data:
  order_data:

networks:
  default:
    name: ${PROJECT_NAME}-network
EOF
    
    print_success "docker-compose.yml created successfully"
}

# Function to deploy with Docker Compose
deploy_docker_compose() {
    print_step "Deploying with Docker Compose..."
    
    # Stop existing containers
    docker-compose down 2>/dev/null || true
    
    # Start services
    docker-compose up -d
    
    print_success "Docker Compose deployment completed"
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 15
    
    # Check service health
    print_status "Checking service health..."
    
    check_service_health() {
        local service=$1
        local port=$2
        local max_attempts=30
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -f -s "http://localhost:${port}/health" > /dev/null 2>&1; then
                print_success "${service} is healthy"
                return 0
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                print_warning "${service} health check failed after ${max_attempts} attempts"
                return 1
            fi
            
            sleep 2
            ((attempt++))
        done
    }
    
    check_service_health "user-service" "8001"
    check_service_health "catalog-service" "8002"
    check_service_health "order-service" "8003"
    
    # Check frontend
    if curl -f -s "http://localhost:3000" > /dev/null 2>&1; then
        print_success "frontend-service is accessible"
    else
        print_warning "frontend-service may not be ready yet"
    fi
}

# Function to seed data for Docker Compose
seed_docker_data() {
    print_step "Seeding initial data for Docker Compose..."
    
    print_status "Creating admin user..."
    docker-compose exec -T user-service python -c "
import requests
import sys
try:
    response = requests.post('http://localhost:8000/register', json={
        'email': 'admin@seneca.ca',
        'password': 'admin123',
        'is_admin': True
    })
    if response.status_code in [200, 201]:
        print('Admin user created successfully')
    else:
        print('Admin user may already exist')
except Exception as e:
    print(f'Error creating admin user: {e}')
" || print_warning "Failed to create admin user (may already exist)"
    
    print_status "Creating regular user..."
    docker-compose exec -T user-service python -c "
import requests
import sys
try:
    response = requests.post('http://localhost:8000/register', json={
        'email': 'user@seneca.ca',
        'password': 'user123',
        'is_admin': False
    })
    if response.status_code in [200, 201]:
        print('Regular user created successfully')
    else:
        print('Regular user may already exist')
except Exception as e:
    print(f'Error creating regular user: {e}')
" || print_warning "Failed to create regular user (may already exist)"
    
    print_success "Docker Compose data seeding completed!"
}

# ==============================
# KUBERNETES DEPLOYMENT FUNCTIONS
# ==============================

# Function to check Minikube status
check_minikube() {
    print_step "Checking Minikube status..."
    
    if ! minikube status >/dev/null 2>&1; then
        print_warning "Minikube is not running"
        print_status "Starting Minikube..."
        
        # Start Minikube with appropriate settings
        minikube start \
            --driver=docker \
            --memory=8192 \
            --cpus=4 \
            --disk-size=20g \
            --kubernetes-version=v1.28.0 \
            --addons=ingress,registry,dashboard,metrics-server
        
        print_success "Minikube started successfully!"
    else
        print_success "Minikube is already running"
    fi
    
    # Configure kubectl context
    kubectl config use-context minikube
    print_success "kubectl context set to minikube"
}

# Function to enable required addons
enable_addons() {
    print_step "Enabling required Minikube addons..."
    
    local addons=("ingress" "registry" "dashboard" "metrics-server")
    
    for addon in "${addons[@]}"; do
        if minikube addons list | grep -q "$addon.*enabled"; then
            print_status "$addon addon is already enabled"
        else
            print_status "Enabling $addon addon..."
            minikube addons enable "$addon"
        fi
    done
    
    print_success "All required addons enabled!"
}

# Function to install cert-manager
install_cert_manager() {
    print_step "Installing cert-manager..."
    
    if kubectl get namespace cert-manager >/dev/null 2>&1; then
        print_status "cert-manager is already installed"
    else
        print_status "Installing cert-manager..."
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
        
        print_status "Waiting for cert-manager to be ready..."
        kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=300s
        kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n cert-manager --timeout=300s
        kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=300s
        
        print_success "cert-manager installed successfully!"
    fi
}

# Function to setup local registry access
setup_registry() {
    print_step "Setting up local registry access..."
    
    # Enable registry addon if not already enabled
    if ! minikube addons list | grep -q "registry.*enabled"; then
        minikube addons enable registry
    fi
    
    # Port forward registry if not already running
    if ! lsof -i :5000 >/dev/null 2>&1; then
        print_status "Setting up registry port forwarding..."
        kubectl port-forward --namespace kube-system service/registry 5000:80 &
        sleep 5
    fi
    
    print_success "Registry access configured!"
}

# Function to push images to registry
push_images() {
    print_step "Pushing images to registry..."
    
    local services=("user-service" "catalog-service" "order-service" "frontend-service")
    
    for service in "${services[@]}"; do
        print_status "Pushing $service image..."
        docker push "$REGISTRY/$service:$VERSION" || print_warning "Failed to push $service image"
    done
    
    print_success "Images pushed to registry!"
}

# Function to create namespace and apply configurations
apply_configs() {
    print_step "Applying Kubernetes configurations..."
    
    # Apply configurations in order
    local manifests=(
        "00-namespace.yaml"
        "01-config.yaml"
        "02-storage.yaml"
        "04-rbac.yaml"
        "05-network-policy.yaml"
        "08-monitoring-rbac.yaml"
        "06-prometheus.yaml"
        "07-grafana.yaml"
        "user-service.yaml"
        "catalog-service.yaml"
        "order-service.yaml"
        "frontend-service.yaml"
        "03-ingress.yaml"
    )
    
    for manifest in "${manifests[@]}"; do
        if [ -f "k8s-manifests/$manifest" ]; then
            print_status "Applying $manifest..."
            kubectl apply -f "k8s-manifests/$manifest"
        else
            print_warning "Manifest $manifest not found, skipping..."
        fi
    done
    
    print_success "Kubernetes configurations applied!"
}

# Function to wait for deployments
wait_for_deployments() {
    print_step "Waiting for deployments to be ready..."
    
    local deployments=("user-service" "catalog-service" "order-service" "frontend-service")
    
    for deployment in "${deployments[@]}"; do
        print_status "Waiting for $deployment deployment..."
        kubectl wait --for=condition=Available deployment/$deployment -n $NAMESPACE --timeout=300s
    done
    
    print_success "All deployments are ready!"
}

# Function to setup hosts file
setup_hosts() {
    print_step "Setting up hosts file..."
    
    local minikube_ip=$(minikube ip)
    local hosts_entry="$minikube_ip $DOMAIN"
    
    if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
        print_status "Updating existing hosts entry..."
        sudo sed -i "s/.*$DOMAIN.*/$hosts_entry/" /etc/hosts
    else
        print_status "Adding new hosts entry..."
        echo "$hosts_entry" | sudo tee -a /etc/hosts
    fi
    
    print_success "Hosts file updated: $hosts_entry"
}

# Function to run Kubernetes tests
run_k8s_tests() {
    print_step "Running Kubernetes health checks..."
    
    # Wait a bit for services to stabilize
    sleep 10
    
    local services=("user-service" "catalog-service" "order-service")
    
    for service in "${services[@]}"; do
        print_status "Testing $service health endpoint..."
        
        if kubectl exec -n $NAMESPACE deployment/$service -- curl -f http://localhost:8000/health >/dev/null 2>&1; then
            print_success "$service health check passed"
        else
            print_warning "$service health check failed"
        fi
    done
    
    print_success "Kubernetes health checks completed!"
}

# Function to seed initial data for Kubernetes
seed_k8s_data() {
    print_step "Seeding initial data for Kubernetes..."
    
    print_status "Creating admin user..."
    kubectl exec -n $NAMESPACE deployment/user-service -- python -c "
import requests
import sys
try:
    response = requests.post('http://localhost:8000/register', json={
        'email': 'admin@seneca.ca',
        'password': 'admin123',
        'is_admin': True
    })
    if response.status_code in [200, 201]:
        print('Admin user created successfully')
    else:
        print('Admin user may already exist')
except Exception as e:
    print(f'Error creating admin user: {e}')
" || print_warning "Failed to create admin user (may already exist)"
    
    print_status "Creating regular user..."
    kubectl exec -n $NAMESPACE deployment/user-service -- python -c "
import requests
import sys
try:
    response = requests.post('http://localhost:8000/register', json={
        'email': 'user@seneca.ca',
        'password': 'user123',
        'is_admin': False
    })
    if response.status_code in [200, 201]:
        print('Regular user created successfully')
    else:
        print('Regular user may already exist')
except Exception as e:
    print(f'Error creating regular user: {e}')
" || print_warning "Failed to create regular user (may already exist)"
    
    print_status "Creating sample books..."
    kubectl exec -n $NAMESPACE deployment/catalog-service -- python -c "
import requests
import sys
try:
    # First login as admin to get token
    login_response = requests.post('http://user-service:8000/login', data={
        'username': 'admin@seneca.ca',
        'password': 'admin123'
    })
    if login_response.status_code == 200:
        token = login_response.json().get('access_token')
        headers = {'Authorization': f'Bearer {token}'}
        
        # Seed books
        seed_response = requests.post('http://localhost:8000/books/seed', headers=headers)
        if seed_response.status_code == 200:
            print('Sample books created successfully')
        else:
            print('Sample books may already exist')
    else:
        print('Failed to login as admin')
except Exception as e:
    print(f'Error seeding books: {e}')
" || print_warning "Failed to seed books"
    
    print_success "Kubernetes data seeding completed!"
}

# Function to deploy to Kubernetes
deploy_kubernetes() {
    if [ "$SKIP_K8S" = true ]; then
        print_warning "Skipping Kubernetes deployment"
        return
    fi
    
    print_step "Deploying to Kubernetes..."
    
    check_minikube
    enable_addons
    install_cert_manager
    setup_registry
    push_images
    apply_configs
    wait_for_deployments
    setup_hosts
    run_k8s_tests
    seed_k8s_data
}

# Function to show deployment summary
show_summary() {
    print_header
    print_success "🎉 Seneca Book Store deployed successfully!"
    echo
    
    if [ "$DEPLOYMENT_MODE" = "docker" ] || [ "$DEPLOYMENT_MODE" = "both" ]; then
        print_status "🐳 Docker Compose Services:"
        echo "  👤 User Service: http://localhost:8001"
        echo "  📚 Catalog Service: http://localhost:8002"
        echo "  🛒 Order Service: http://localhost:8003"
        echo "  🌐 Frontend: http://localhost:3000"
        echo
        
        print_status "🛠️ Docker Commands:"
        echo "  📝 View logs: docker-compose logs -f [service-name]"
        echo "  🔄 Restart: docker-compose restart [service-name]"
        echo "  🛑 Stop: docker-compose down"
        echo
    fi
    
    if [ "$DEPLOYMENT_MODE" = "kubernetes" ] || ([ "$DEPLOYMENT_MODE" = "both" ] && [ "$SKIP_K8S" != true ]); then
        print_status "☸️ Kubernetes Services:"
        echo "  🌐 Application: https://$DOMAIN"
        echo "  🔧 Dashboard: minikube dashboard"
        echo "  📊 Namespace: $NAMESPACE"
        echo
        
        print_status "🛠️ Kubernetes Commands:"
        echo "  📝 View logs: kubectl logs -f deployment/<service> -n $NAMESPACE"
        echo "  🔍 Check pods: kubectl get pods -n $NAMESPACE"
        echo "  🌐 Port forward: kubectl port-forward service/<service> <port>:8000 -n $NAMESPACE"
        echo "  🚀 Scale: kubectl scale deployment <service> --replicas=<count> -n $NAMESPACE"
        echo
        
        print_status "🎯 Quick Access:"
        echo "  📱 Frontend: https://$DOMAIN"
        echo "  🔐 User API: https://$DOMAIN/api/user/docs"
        echo "  📚 Catalog API: https://$DOMAIN/api/catalog/docs"
        echo "  🛒 Order API: https://$DOMAIN/api/order/docs"
        echo
    fi
    
    print_status "🔐 Default Credentials:"
    echo "  👑 Admin: admin@seneca.ca / admin123"
    echo "  👤 User: user@seneca.ca / user123"
    echo
}

# Function to show status
show_status() {
    print_header
    print_status "📊 Deployment Status"
    echo
    
    if [ "$DEPLOYMENT_MODE" = "docker" ] || [ "$DEPLOYMENT_MODE" = "both" ]; then
        print_status "🐳 Docker Compose Status:"
        docker-compose ps 2>/dev/null || echo "Docker Compose not running"
        echo
    fi
    
    if [ "$DEPLOYMENT_MODE" = "kubernetes" ] || ([ "$DEPLOYMENT_MODE" = "both" ] && [ "$SKIP_K8S" != true ]); then
        print_status "☸️ Minikube Status:"
        minikube status 2>/dev/null || echo "Minikube not running"
        echo
        
        print_status "📦 Kubernetes Pods:"
        kubectl get pods -n $NAMESPACE 2>/dev/null || echo "Namespace not found"
        echo
        
        print_status "🔗 Kubernetes Services:"
        kubectl get services -n $NAMESPACE 2>/dev/null || echo "Namespace not found"
        echo
    fi
}

# Function to show logs
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo "Available services: user-service, catalog-service, order-service, frontend-service"
        read -p "Enter service name: " service
    fi
    
    if [ "$DEPLOYMENT_MODE" = "docker" ]; then
        docker-compose logs -f $service
    elif [ "$DEPLOYMENT_MODE" = "kubernetes" ]; then
        kubectl logs -f deployment/$service -n $NAMESPACE
    else
        echo "Please specify --docker or --k8s mode"
    fi
}

# Function to cleanup
cleanup() {
    print_step "Cleaning up deployments..."
    
    if [ "$DEPLOYMENT_MODE" = "docker" ] || [ "$DEPLOYMENT_MODE" = "both" ]; then
        print_status "Stopping Docker Compose..."
        docker-compose down -v 2>/dev/null || true
    fi
    
    if [ "$DEPLOYMENT_MODE" = "kubernetes" ] || ([ "$DEPLOYMENT_MODE" = "both" ] && [ "$SKIP_K8S" != true ]); then
        print_status "Cleaning up Kubernetes..."
        kubectl delete namespace $NAMESPACE --ignore-not-found=true
        
        # Clean up hosts entry
        if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
            sudo sed -i "/$DOMAIN/d" /etc/hosts
        fi
    fi
    
    print_success "Cleanup completed!"
}

# Function to show help
show_help() {
    echo "Seneca Book Store - Unified Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo
    echo "Deployment Modes:"
    echo "  --docker       Deploy using Docker Compose only"
    echo "  --k8s          Deploy using Kubernetes only"
    echo "  --both         Deploy using both Docker Compose and Kubernetes (default)"
    echo
    echo "Commands:"
    echo "  deploy         Full deployment (default)"
    echo "  build          Build Docker images only"
    echo "  status         Show deployment status"
    echo "  logs [service] Show logs for service"
    echo "  cleanup        Clean up all deployments"
    echo "  seed           Seed initial data"
    echo "  help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --docker deploy     # Deploy with Docker Compose only"
    echo "  $0 --k8s deploy        # Deploy with Kubernetes only"
    echo "  $0 --both deploy       # Deploy with both (default)"
    echo "  $0 status              # Show deployment status"
    echo "  $0 logs user-service   # Show logs for user service"
    echo "  $0 cleanup             # Clean up all deployments"
}

# Main deployment functions
deploy_docker_only() {
    print_header
    check_prerequisites
    build_images
    create_docker_compose
    deploy_docker_compose
    seed_docker_data
    show_summary
}

deploy_k8s_only() {
    print_header
    check_prerequisites
    build_images
    deploy_kubernetes
    show_summary
}

deploy_both() {
    print_header
    check_prerequisites
    build_images
    
    print_status "Deploying with Docker Compose first..."
    create_docker_compose
    deploy_docker_compose
    seed_docker_data
    
    print_status "Now deploying with Kubernetes..."
    deploy_kubernetes
    
    show_summary
}

# Parse arguments
DEPLOYMENT_MODE="both"
SKIP_K8S=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --docker)
            DEPLOYMENT_MODE="docker"
            shift
            ;;
        --k8s|--kubernetes)
            DEPLOYMENT_MODE="kubernetes"
            shift
            ;;
        --both)
            DEPLOYMENT_MODE="both"
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Main script logic
case "${1:-deploy}" in
    deploy)
        case $DEPLOYMENT_MODE in
            docker)
                deploy_docker_only
                ;;
            kubernetes)
                deploy_k8s_only
                ;;
            both)
                deploy_both
                ;;
        esac
        ;;
    build)
        check_prerequisites
        if [ "$DEPLOYMENT_MODE" = "kubernetes" ]; then
            check_minikube
            setup_registry
        fi
        build_images
        if [ "$DEPLOYMENT_MODE" = "kubernetes" ]; then
            push_images
        fi
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs $2
        ;;
    cleanup)
        cleanup
        ;;
    seed)
        if [ "$DEPLOYMENT_MODE" = "docker" ]; then
            seed_docker_data
        elif [ "$DEPLOYMENT_MODE" = "kubernetes" ]; then
            seed_k8s_data
        else
            echo "Please specify --docker or --k8s mode for seeding"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
