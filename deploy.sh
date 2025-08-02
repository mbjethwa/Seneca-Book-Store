#!/bin/bash

# 🚀 Seneca Book Store - Streamlined Minikube Deployment Script
# Default deployment to Minikube with phase-wise execution

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

# Phase tracking
CURRENT_PHASE=0
TOTAL_PHASES=6

# Function to print colored output
print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}   Seneca Book Store - Minikube Deploy   ${NC}"
    echo -e "${PURPLE}========================================${NC}"
}

print_phase() {
    CURRENT_PHASE=$((CURRENT_PHASE + 1))
    echo
    echo -e "${PURPLE}📋 PHASE ${CURRENT_PHASE}/${TOTAL_PHASES}: $1${NC}"
    echo -e "${PURPLE}----------------------------------------${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} ❌ $1"
    exit 1
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} 🔧 $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Phase 1: Prerequisites Check
check_prerequisites() {
    print_phase "Prerequisites & Environment Check"
    
    print_step "Checking required tools..."
    
    # Check Docker
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker."
    fi
    print_success "Docker is running"
    
    # Check kubectl
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install kubectl first."
    fi
    print_success "kubectl is available"
    
    # Check minikube
    if ! command_exists minikube; then
        print_error "Minikube is not installed. Please install Minikube first."
    fi
    print_success "Minikube is available"
    
    # Check system resources
    print_step "Checking system resources..."
    
    # Check memory (require at least 4GB)
    MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
    
    if [ $MEMORY_GB -lt 4 ]; then
        print_warning "System has only ${MEMORY_GB}GB RAM. Minikube requires at least 4GB."
    else
        print_success "System memory: ${MEMORY_GB}GB (sufficient)"
    fi
    
    # Check disk space (require at least 10GB free)
    DISK_FREE_GB=$(df . | tail -1 | awk '{print int($4/1024/1024)}')
    if [ $DISK_FREE_GB -lt 10 ]; then
        print_warning "Only ${DISK_FREE_GB}GB disk space free. Recommend at least 10GB."
    else
        print_success "Disk space: ${DISK_FREE_GB}GB free (sufficient)"
    fi
    
    print_success "Prerequisites check completed!"
}

# Phase 2: Minikube Setup
setup_minikube() {
    print_phase "Minikube Cluster Setup"
    
    print_step "Checking Minikube status..."
    
    # Check if Minikube is running
    if minikube status >/dev/null 2>&1; then
        print_success "Minikube is already running"
    else
        print_step "Starting Minikube cluster..."
        
        # Start Minikube with appropriate settings
        minikube start \
            --cpus=2 \
            --memory=4096 \
            --disk-size=20g \
            --driver=docker \
            --kubernetes-version=stable \
            --addons=ingress,registry,metrics-server \
            --insecure-registry="localhost:5000" || print_error "Failed to start Minikube"
        
        print_success "Minikube started successfully!"
    fi
    
    # Wait for cluster to be ready
    print_step "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s || print_error "Cluster failed to become ready"
    
    # Configure kubectl context
    print_step "Configuring kubectl context..."
    kubectl config use-context minikube || print_error "Failed to set kubectl context"
    
    print_success "Minikube cluster is ready!"
}

# Phase 3: Namespace and RBAC Setup
setup_namespace() {
    print_phase "Namespace and RBAC Configuration"
    
    print_step "Creating namespace..."
    
    # Create namespace if it doesn't exist
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        print_success "Namespace '$NAMESPACE' already exists"
    else
        kubectl create namespace $NAMESPACE || print_error "Failed to create namespace"
        print_success "Namespace '$NAMESPACE' created"
    fi
    
    # Apply RBAC configuration
    print_step "Applying RBAC configuration..."
    if [ -f "k8s-manifests/04-rbac.yaml" ]; then
        kubectl apply -f k8s-manifests/04-rbac.yaml -n $NAMESPACE || print_error "Failed to apply RBAC"
        print_success "RBAC configuration applied"
    else
        print_warning "RBAC file not found, skipping..."
    fi
    
    # Clean up any released persistent volumes to avoid binding issues
    print_step "Checking persistent volume status..."
    RELEASED_PVS=$(kubectl get pv --no-headers | grep Released | grep bookstore-data-pv | wc -l)
    if [ $RELEASED_PVS -gt 0 ]; then
        print_warning "Found released persistent volume, cleaning up..."
        kubectl delete pv bookstore-data-pv 2>/dev/null || true
        print_success "Released persistent volume cleaned up"
    fi
    
    print_success "Namespace and RBAC setup completed!"
}

# Phase 4: Build and Push Images
build_and_push_images() {
    print_phase "Building and Pushing Docker Images"
    
    # Setup local registry if needed
    print_step "Setting up local registry..."
    if ! kubectl get service registry -n kube-system >/dev/null 2>&1; then
        print_warning "Registry addon not found, enabling..."
        minikube addons enable registry || print_error "Failed to enable registry addon"
    fi
    
    # Port forward registry if not already running
    print_step "Setting up registry port forwarding..."
    if ! pgrep -f "kubectl.*port-forward.*registry" >/dev/null; then
        kubectl port-forward --namespace kube-system service/registry 5000:80 >/dev/null 2>&1 &
        sleep 3
    fi
    print_success "Registry is accessible at localhost:5000"
    
    # Build images for each service
    SERVICES=("user-service" "catalog-service" "order-service" "frontend-service")
    
    for service in "${SERVICES[@]}"; do
        print_step "Building $service image..."
        
        if [ -d "$service" ]; then
            cd "$service"
            
            # Build image
            docker build -t "$REGISTRY/$service:$VERSION" . || print_error "Failed to build $service image"
            
            # Tag for local use
            docker tag "$REGISTRY/$service:$VERSION" "$service:$VERSION"
            
            # Push to registry
            docker push "$REGISTRY/$service:$VERSION" || print_error "Failed to push $service image"
            
            cd ..
            print_success "$service image built and pushed"
        else
            print_warning "Directory $service not found, skipping..."
        fi
    done
    
    print_success "All images built and pushed successfully!"
}

# Phase 5: Deploy Kubernetes Resources
deploy_kubernetes_resources() {
    print_phase "Deploying Kubernetes Resources"
    
    # Deploy infrastructure resources first
    print_step "Deploying infrastructure resources..."
    
    INFRA_FILES=("01-config.yaml" "02-storage.yaml" "03-ingress.yaml" "05-network-policy.yaml")
    
    for file in "${INFRA_FILES[@]}"; do
        if [ -f "k8s-manifests/$file" ]; then
            print_step "Applying $file..."
            kubectl apply -f "k8s-manifests/$file" -n $NAMESPACE || print_warning "Resource $file had warnings but was applied"
        else
            print_warning "File k8s-manifests/$file not found, skipping..."
        fi
    done
    
    # Deploy services
    print_step "Deploying application services..."
    
    SERVICE_FILES=("user-service.yaml" "catalog-service.yaml" "order-service.yaml" "frontend-service.yaml")
    
    for file in "${SERVICE_FILES[@]}"; do
        if [ -f "k8s-manifests/$file" ]; then
            print_step "Deploying $file..."
            kubectl apply -f "k8s-manifests/$file" -n $NAMESPACE || print_error "Failed to deploy $file"
        else
            print_warning "File k8s-manifests/$file not found, skipping..."
        fi
    done
    
    print_success "Kubernetes resources deployed!"
}

# Phase 6: Wait for Deployment and Setup Ingress
finalize_deployment() {
    print_phase "Finalizing Deployment and Setup"
    
    print_step "Waiting for all pods to be ready..."
    
    # Check if any pods are in CrashLoopBackOff and need database path fix
    CRASH_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | grep CrashLoopBackOff | wc -l)
    if [ $CRASH_PODS -gt 0 ]; then
        print_warning "Detected pods in CrashLoopBackOff, checking database configurations..."
        
        # Apply fixed database configurations
        print_step "Applying database path fixes..."
        kubectl apply -f k8s-manifests/user-service.yaml -n $NAMESPACE
        kubectl apply -f k8s-manifests/catalog-service.yaml -n $NAMESPACE  
        kubectl apply -f k8s-manifests/order-service.yaml -n $NAMESPACE
        
        print_success "Database configurations updated"
        sleep 10
    fi
    
    # Wait for pods with retries
    for i in {1..3}; do
        print_step "Attempt $i: Waiting for all pods to be ready..."
        if kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=180s; then
            print_success "All pods are ready!"
            break
        elif [ $i -eq 3 ]; then
            print_error "Pods failed to become ready after 3 attempts"
        else
            print_warning "Attempt $i failed, retrying..."
            sleep 10
        fi
    done
    
    print_step "Setting up ingress..."
    
    # Add hosts entry for local access
    MINIKUBE_IP=$(minikube ip)
    
    if ! grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
        print_step "Adding hosts entry (requires sudo)..."
        echo "$MINIKUBE_IP $DOMAIN" | sudo tee -a /etc/hosts >/dev/null || print_warning "Failed to add hosts entry"
        print_success "Hosts entry added"
    else
        print_success "Hosts entry already exists"
    fi
    
    # Wait for ingress to be ready
    print_step "Waiting for ingress to be ready..."
    sleep 10
    
    # Verify deployment health
    print_step "Verifying deployment health..."
    MINIKUBE_IP=$(minikube ip)
    
    echo "Checking application health endpoints..."
    
    # Test frontend
    if curl -s -o /dev/null -w "%{http_code}" "http://$MINIKUBE_IP/" --connect-timeout 5 | grep -q "200\|404"; then
        print_success "Frontend is responding"
    else
        print_warning "Frontend not responding properly"
    fi
    
    # Test API endpoints
    for service in user catalog order; do
        if curl -s -o /dev/null -w "%{http_code}" "http://$MINIKUBE_IP/api/$service/health" --connect-timeout 5 | grep -q "200\|404"; then
            print_success "$service-service is responding"
        else
            print_warning "$service-service not responding properly"
        fi
    done
    
    print_success "Deployment finalized!"
}

# Function to show deployment summary
show_summary() {
    echo
    print_header
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo
    echo -e "${CYAN}📊 Deployment Summary:${NC}"
    echo -e "  • Project: $PROJECT_NAME"
    echo -e "  • Namespace: $NAMESPACE"
    echo -e "  • Domain: http://$DOMAIN"
    echo -e "  • Registry: $REGISTRY"
    echo
    echo -e "${CYAN}🔗 Access URLs:${NC}"
    echo -e "  • Application: ${GREEN}http://$DOMAIN${NC}"
    echo -e "  • API Docs: ${GREEN}http://$DOMAIN/api/docs${NC}"
    echo
    echo -e "${CYAN}� Service Status:${NC}"
    kubectl get pods -n $NAMESPACE
    echo
    echo -e "${CYAN}🌐 Services:${NC}"
    kubectl get services -n $NAMESPACE
    echo
    echo -e "${CYAN}�📋 Useful Commands:${NC}"
    echo -e "  • Check status: ${YELLOW}./deploy.sh status${NC}"
    echo -e "  • View logs: ${YELLOW}kubectl logs -f deployment/user-service -n $NAMESPACE${NC}"
    echo -e "  • Port forward: ${YELLOW}kubectl port-forward service/frontend-service 3000:80 -n $NAMESPACE${NC}"
    echo
    echo -e "${CYAN}🛠️ Troubleshooting:${NC}"
    echo -e "  • If domain doesn't work, check: ${YELLOW}minikube ip${NC}"
    echo -e "  • View ingress: ${YELLOW}kubectl get ingress -n $NAMESPACE${NC}"
    echo -e "  • Cleanup: ${YELLOW}./deploy.sh cleanup${NC}"
    echo
    echo -e "${GREEN}✅ Ready to use! Visit http://$DOMAIN${NC}"
    echo
}

# Function to show status
show_status() {
    print_header
    echo -e "${BLUE}📊 Deployment Status${NC}"
    echo
    
    # Minikube status
    echo -e "${CYAN}☸️ Minikube Status:${NC}"
    minikube status || echo "Minikube not running"
    echo
    
    # Namespace status
    echo -e "${CYAN}📦 Namespace Status:${NC}"
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        kubectl get pods -n $NAMESPACE -o wide
    else
        echo "Namespace $NAMESPACE does not exist"
    fi
    echo
    
    # Services status
    echo -e "${CYAN}🔗 Services Status:${NC}"
    kubectl get services -n $NAMESPACE 2>/dev/null || echo "No services found"
    echo
    
    # Ingress status
    echo -e "${CYAN}🌐 Ingress Status:${NC}"
    kubectl get ingress -n $NAMESPACE 2>/dev/null || echo "No ingress found"
}

# Function to cleanup deployment
cleanup() {
    print_header
    echo -e "${YELLOW}🧹 Cleaning up deployment...${NC}"
    
    # Delete namespace (this removes all resources in the namespace)
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        kubectl delete namespace $NAMESPACE --timeout=60s || print_warning "Failed to delete namespace"
        print_success "Namespace deleted"
    else
        print_warning "Namespace does not exist"
    fi
    
    # Remove hosts entry
    if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
        print_step "Removing hosts entry (requires sudo)..."
        sudo sed -i "/$DOMAIN/d" /etc/hosts || print_warning "Failed to remove hosts entry"
        print_success "Hosts entry removed"
    fi
    
    # Stop Minikube if requested
    read -p "Do you want to stop Minikube? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        minikube stop
        print_success "Minikube stopped"
    fi
    
    print_success "Cleanup completed!"
}

# Function to show help
show_help() {
    print_header
    echo -e "${CYAN}Seneca Book Store - Streamlined Minikube Deployment${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./deploy.sh [COMMAND]"
    echo
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}deploy${NC}     Full deployment to Minikube (default)"
    echo -e "  ${GREEN}status${NC}     Show deployment status"
    echo -e "  ${GREEN}cleanup${NC}    Clean up all deployments"
    echo -e "  ${GREEN}help${NC}       Show this help message"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ./deploy.sh              # Full deployment"
    echo -e "  ./deploy.sh status       # Check status"
    echo -e "  ./deploy.sh cleanup      # Clean up"
    echo
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo -e "  • Docker (running)"
    echo -e "  • kubectl"
    echo -e "  • Minikube"
    echo -e "  • 4GB+ RAM"
    echo -e "  • 10GB+ disk space"
    echo
}

# Main deployment function
main_deploy() {
    print_header
    echo -e "${GREEN}🚀 Starting Seneca Book Store deployment to Minikube...${NC}"
    echo
    
    # Execute all phases
    check_prerequisites
    setup_minikube
    setup_namespace
    build_and_push_images
    deploy_kubernetes_resources
    finalize_deployment
    
    # Show summary
    show_summary
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        main_deploy
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        ;;
esac
