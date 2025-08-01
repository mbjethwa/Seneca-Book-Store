#!/bin/bash

# Seneca Book Store - Automated Deployment Script
# This script builds and deploys the entire microservices application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="seneca-book-store"
REGISTRY="localhost:5000"  # Change this to your registry
VERSION="latest"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command_exists kubectl; then
        print_warning "kubectl not found. Kubernetes deployment will be skipped."
        SKIP_K8S=true
    fi
    
    if ! command_exists npm; then
        print_error "npm is not installed or not in PATH"
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Function to build Docker images
build_images() {
    print_status "Building Docker images..."
    
    # Build backend services
    services=("user-service" "catalog-service" "order-service")
    
    for service in "${services[@]}"; do
        print_status "Building ${service}..."
        cd "${service}"
        docker build -t "${REGISTRY}/${service}:${VERSION}" .
        cd ..
        print_success "${service} image built successfully"
    done
    
    # Build frontend service
    print_status "Building frontend-service..."
    cd frontend-service
    docker build -t "${REGISTRY}/frontend-service:${VERSION}" .
    cd ..
    print_success "frontend-service image built successfully"
    
    print_success "All Docker images built successfully"
}

# Function to create docker-compose file
create_docker_compose() {
    print_status "Creating docker-compose.yml..."
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  user-service:
    image: ${REGISTRY}/user-service:${VERSION}
    ports:
      - "8001:8000"
    environment:
      - PORT=8000
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  catalog-service:
    image: ${REGISTRY}/catalog-service:${VERSION}
    ports:
      - "8002:8000"
    environment:
      - PORT=8000
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  order-service:
    image: ${REGISTRY}/order-service:${VERSION}
    ports:
      - "8003:8000"
    environment:
      - PORT=8000
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

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

networks:
  default:
    name: ${PROJECT_NAME}-network
EOF
    
    print_success "docker-compose.yml created successfully"
}

# Function to deploy with Docker Compose
deploy_docker_compose() {
    print_status "Deploying with Docker Compose..."
    
    # Stop existing containers
    docker-compose down 2>/dev/null || true
    
    # Start services
    docker-compose up -d
    
    print_success "Docker Compose deployment completed"
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
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

# Function to deploy to Kubernetes
deploy_kubernetes() {
    if [ "$SKIP_K8S" = true ]; then
        print_warning "Skipping Kubernetes deployment (kubectl not found)"
        return
    fi
    
    print_status "Deploying to Kubernetes..."
    
    # Check if cluster is accessible
    if ! kubectl cluster-info > /dev/null 2>&1; then
        print_warning "Kubernetes cluster not accessible. Skipping K8s deployment."
        return
    fi
    
    # Create namespace if it doesn't exist
    kubectl create namespace ${PROJECT_NAME} --dry-run=client -o yaml | kubectl apply -f -
    
    # Update image references in manifests
    print_status "Updating Kubernetes manifests..."
    
    for manifest in k8s-manifests/*.yaml; do
        # Create temporary file with updated image references
        sed "s|image: \([^:]*\):latest|image: ${REGISTRY}/\1:${VERSION}|g" "$manifest" > "${manifest}.tmp"
        mv "${manifest}.tmp" "$manifest"
    done
    
    # Apply manifests
    kubectl apply -f k8s-manifests/ -n ${PROJECT_NAME}
    
    # Wait for deployments
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment --all -n ${PROJECT_NAME}
    
    print_success "Kubernetes deployment completed"
    
    # Show service information
    print_status "Service information:"
    kubectl get services -n ${PROJECT_NAME}
}

# Function to show deployment summary
show_summary() {
    print_success "Deployment Summary"
    echo "=================="
    echo
    print_status "Docker Compose Services:"
    echo "- User Service: http://localhost:8001"
    echo "- Catalog Service: http://localhost:8002"
    echo "- Order Service: http://localhost:8003"
    echo "- Frontend: http://localhost:3000"
    echo
    
    if [ "$SKIP_K8S" != true ]; then
        print_status "Kubernetes Services:"
        kubectl get services -n ${PROJECT_NAME} 2>/dev/null || echo "No Kubernetes services found"
        echo
    fi
    
    print_status "Useful Commands:"
    echo "- View logs: docker-compose logs -f [service-name]"
    echo "- Stop services: docker-compose down"
    echo "- Restart services: docker-compose restart [service-name]"
    
    if [ "$SKIP_K8S" != true ]; then
        echo "- K8s logs: kubectl logs -f deployment/[service-name] -n ${PROJECT_NAME}"
        echo "- K8s status: kubectl get pods -n ${PROJECT_NAME}"
    fi
}

# Function to cleanup
cleanup() {
    if [ "$1" = "--clean" ]; then
        print_status "Cleaning up existing deployments..."
        docker-compose down 2>/dev/null || true
        
        if [ "$SKIP_K8S" != true ]; then
            kubectl delete namespace ${PROJECT_NAME} --ignore-not-found=true
        fi
        
        print_success "Cleanup completed"
    fi
}

# Main execution
main() {
    echo "========================================"
    echo "   Seneca Book Store Deployment Script   "
    echo "========================================"
    echo
    
    # Parse arguments
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --clean    Clean up existing deployments before deploying"
        echo "  --docker   Deploy only with Docker Compose (skip Kubernetes)"
        echo "  --k8s      Deploy only to Kubernetes (skip Docker Compose)"
        echo "  --help     Show this help message"
        echo
        exit 0
    fi
    
    if [ "$1" = "--clean" ]; then
        cleanup --clean
        shift
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Build images
    build_images
    
    # Deploy based on arguments
    if [ "$1" = "--k8s" ]; then
        deploy_kubernetes
    elif [ "$1" = "--docker" ]; then
        create_docker_compose
        deploy_docker_compose
    else
        # Default: deploy both
        create_docker_compose
        deploy_docker_compose
        deploy_kubernetes
    fi
    
    # Show summary
    show_summary
    
    print_success "Deployment script completed successfully!"
}

# Run main function with all arguments
main "$@"
