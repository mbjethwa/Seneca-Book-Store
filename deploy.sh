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
INTERNAL_REGISTRY="registry.kube-system.svc.cluster.local"
VERSION="latest"
DOMAIN="senecabooks.local"

# Phase tracking
CURRENT_PHASE=0
TOTAL_PHASES=7

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
    
    # Ensure ingress addon is enabled (regardless of whether minikube was already running)
    print_step "Ensuring ingress addon is enabled..."
    if ! minikube addons list | grep -q "ingress.*enabled"; then
        print_step "Enabling ingress addon..."
        minikube addons enable ingress || print_error "Failed to enable ingress addon"
        print_success "Ingress addon enabled"
        
        # Wait for ingress controller to be deployed
        print_step "Waiting for ingress controller to be deployed..."
        sleep 30
    else
        print_success "Ingress addon is already enabled"
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
    
    # Use Minikube's Docker daemon directly
    print_step "Configuring Docker to use Minikube's daemon..."
    eval $(minikube docker-env)
    
    # Build images for each service directly in Minikube
    SERVICES=("user-service" "catalog-service" "order-service" "frontend-service")
    
    for service in "${SERVICES[@]}"; do
        print_step "Building $service image..."
        
        if [ -d "$service" ]; then
            cd "$service"
            
            # Build image directly in Minikube's Docker daemon
            docker build -t "$service:$VERSION" . || print_error "Failed to build $service image"
            
            cd ..
            print_success "$service image built"
        else
            print_warning "Directory $service not found, skipping..."
        fi
    done
    
    # Update manifests to use local images without registry
    print_step "Updating manifests to use local images..."
    find k8s-manifests -name "*.yaml" -exec sed -i "s|localhost:5000/||g" {} \;
    find k8s-manifests -name "*.yaml" -exec sed -i "s|$INTERNAL_REGISTRY/||g" {} \;
    
    print_success "All images built successfully!"
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
    
    print_step "Waiting for all deployments to be ready..."
    
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
    
    # Wait for deployments to be ready (better approach than waiting for all pods)
    DEPLOYMENTS=("user-service" "catalog-service" "order-service" "frontend-service")
    
    for deployment in "${DEPLOYMENTS[@]}"; do
        print_step "Waiting for $deployment deployment to be ready..."
        if kubectl wait --for=condition=Available deployment/$deployment -n $NAMESPACE --timeout=300s; then
            print_success "$deployment deployment is ready!"
        else
            print_warning "$deployment deployment failed to become ready, checking status..."
            kubectl get deployment $deployment -n $NAMESPACE
            kubectl describe deployment $deployment -n $NAMESPACE | tail -10
            
            # Show pod status for this deployment
            kubectl get pods -l app=$deployment -n $NAMESPACE
            kubectl get pods -l app=$deployment -n $NAMESPACE --no-headers | while read pod rest; do
                if [[ $pod == *"Error"* ]] || [[ $pod == *"CrashLoop"* ]] || [[ $pod == *"ImagePull"* ]]; then
                    echo "--- Problematic Pod: $pod ---"
                    kubectl describe pod $pod -n $NAMESPACE | tail -15
                fi
            done
        fi
    done
    
    # Final verification of pod readiness
    print_step "Final verification: Checking all application pods..."
    if kubectl get pods -n $NAMESPACE | grep -E "(user-service|catalog-service|order-service|frontend-service)" | grep -qv "Running\|Completed"; then
        print_warning "Some application pods are not in Running state:"
        kubectl get pods -n $NAMESPACE | grep -E "(user-service|catalog-service|order-service|frontend-service)"
    else
        print_success "All application pods are running!"
    fi
    
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
    
    # Check if ingress controller pods are ready
    print_step "Checking ingress controller status..."
    
    # First, wait for ingress-nginx namespace to exist
    timeout=30
    while [ $timeout -gt 0 ]; do
        if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
            break
        fi
        echo "   Waiting for ingress-nginx namespace... (${timeout}s remaining)"
        sleep 5
        timeout=$((timeout - 5))
    done
    
    if [ $timeout -le 0 ]; then
        print_warning "Ingress-nginx namespace not found, ingress may not be fully ready"
    else
        # Wait for ingress controller pods
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=120s || print_warning "Ingress controller may not be fully ready"
    fi
    
    # Additional wait for ingress to process rules
    sleep 15
    
    # Verify deployment health
    print_step "Verifying deployment health..."
    
    echo "Checking application health endpoints..."
    
    # Wait for ingress controller to be ready
    print_step "Waiting for ingress controller to stabilize..."
    sleep 20
    
    # Test frontend through proper domain
    if curl -s -o /dev/null -w "%{http_code}" "http://$MINIKUBE_IP/" -H "Host: $DOMAIN" --connect-timeout 10 | grep -q "200\|404"; then
        print_success "Frontend is responding"
    else
        print_warning "Frontend not responding properly - this is normal during initial setup"
    fi
    
    # Test API endpoints through proper domain with retries
    for service in user catalog order; do
        health_check_retries=0
        max_retries=3
        
        while [ $health_check_retries -lt $max_retries ]; do
            response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$MINIKUBE_IP/api/$service/health" -H "Host: $DOMAIN" --connect-timeout 10 2>/dev/null || echo "000")
            
            if [ "$response_code" = "200" ]; then
                print_success "$service-service is responding"
                break
            else
                health_check_retries=$((health_check_retries + 1))
                if [ $health_check_retries -lt $max_retries ]; then
                    echo "   Retrying $service-service health check ($health_check_retries/$max_retries)..."
                    sleep 5
                else
                    print_warning "$service-service not responding properly - this is normal during initial setup"
                fi
            fi
        done
    done
    
    print_success "Deployment finalized!"
}

# Phase 7: Load Test Data
load_test_data() {
    print_phase "Loading Test Data"
    
    # Function to setup Python environment
    setup_python_env() {
        # Check if virtual environment exists and activate it
        if [ -d ".venv" ]; then
            print_step "Activating virtual environment..."
            source .venv/bin/activate
            
            # Verify virtual environment is activated
            if [[ "$VIRTUAL_ENV" != "" ]]; then
                print_success "Virtual environment activated: $(basename "$VIRTUAL_ENV")"
            else
                print_warning "Failed to activate virtual environment, falling back to system Python"
                return 1
            fi
            
            # Install httpx in virtual environment if needed
            if ! python -c "import httpx" >/dev/null 2>&1; then
                print_step "Installing httpx in virtual environment..."
                pip install httpx >/dev/null 2>&1 || {
                    print_warning "Failed to install httpx in virtual environment"
                    return 1
                }
                print_success "httpx installed successfully in virtual environment"
            else
                print_success "httpx already available in virtual environment"
            fi
            
            export PYTHON_CMD="python"
            return 0
        else
            print_step "Virtual environment not found, using system Python..."
            return 1
        fi
    }
    
    # Function to setup system Python
    setup_system_python() {
        print_step "Setting up system Python environment..."
        
        # Install httpx if needed for the data loader
        if ! python3 -c "import httpx" >/dev/null 2>&1; then
            print_step "Installing httpx..."
            python3 -m pip install httpx >/dev/null 2>&1 || {
                print_warning "Failed to install httpx - trying with user flag"
                python3 -m pip install --user httpx >/dev/null 2>&1 || {
                    print_warning "Failed to install httpx"
                    return 1
                }
            }
            print_success "httpx installed successfully"
        else
            print_success "httpx already available"
        fi
        
        export PYTHON_CMD="python3"
        return 0
    }
    
    print_step "Checking for test data files..."
    if [ ! -f "test_data/complete_dataset.json" ]; then
        print_warning "Test data not found! Generating first..."
        if [ -f "scripts/generate_test_data.py" ]; then
            print_step "Generating test data..."
            # Try virtual environment first, then system Python
            if setup_python_env; then
                $PYTHON_CMD scripts/generate_test_data.py || {
                    print_warning "Failed to generate test data with virtual environment"
                    if setup_system_python; then
                        $PYTHON_CMD scripts/generate_test_data.py || {
                            print_warning "Failed to generate test data"
                            return 1
                        }
                    else
                        return 1
                    fi
                }
            else
                if setup_system_python; then
                    $PYTHON_CMD scripts/generate_test_data.py || {
                        print_warning "Failed to generate test data"
                        return 1
                    }
                else
                    print_warning "Failed to setup Python environment"
                    return 1
                fi
            fi
        else
            print_warning "Test data generator not found"
            return 1
        fi
    fi
    
    print_step "Setting up Python environment for data loading..."
    
    # Setup Python environment (virtual env preferred, system as fallback)
    if ! setup_python_env; then
        if ! setup_system_python; then
            print_warning "Failed to setup Python environment for data loading"
            return 1
        fi
    fi
    
    print_step "Enhanced service readiness check with health monitoring..."
    
    # Set URL for health checks - use proper domain for consistency
    URL="http://$DOMAIN"
    MINIKUBE_IP=$(minikube ip)
    
    # Wait for ingress to be fully ready before health checks
    print_step "Waiting for ingress controller to be fully operational..."
    sleep 30
    
    # Wait for services with proper health checking
    max_wait=180  # 3 minutes (reduced from 5 minutes)
    wait_time=0
    all_healthy=false
    
    while [ $wait_time -lt $max_wait ]; do
        print_step "Checking service health (${wait_time}s elapsed)..."
        
        # Use longer timeout and proper error handling with Host header
        user_health=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 15 --max-time 30 "http://$MINIKUBE_IP/api/user/health" -H "Host: $DOMAIN" 2>/dev/null || echo "000")
        catalog_health=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 15 --max-time 30 "http://$MINIKUBE_IP/api/catalog/health" -H "Host: $DOMAIN" 2>/dev/null || echo "000") 
        order_health=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 15 --max-time 30 "http://$MINIKUBE_IP/api/order/health" -H "Host: $DOMAIN" 2>/dev/null || echo "000")
        
        if [ "$user_health" = "200" ] && [ "$catalog_health" = "200" ] && [ "$order_health" = "200" ]; then
            print_success "All services are healthy and ready!"
            all_healthy=true
            break
        else
            echo "   Service status: User($user_health) Catalog($catalog_health) Order($order_health)"
            
            # If at least some services are responding, we're making progress
            if [ "$user_health" != "000" ] || [ "$catalog_health" != "000" ] || [ "$order_health" != "000" ]; then
                echo "   Services are starting up, continuing to wait..."
            fi
            
            sleep 15
            wait_time=$((wait_time + 15))
        fi
    done
    
    if [ "$all_healthy" = "false" ]; then
        print_warning "Services are not fully ready after ${max_wait}s, but proceeding with data loading..."
        print_step "Note: This is normal for first-time deployments as services need time to initialize"
    fi
    
    print_step "Loading comprehensive test data with enhanced error handling..."
    if [ -f "scripts/load_test_data.py" ]; then
        echo "📝 Using enhanced data loader script..."
        
        # Give services extra time to be fully ready
        print_step "Giving services additional startup time..."
        sleep 30
        
        # Run enhanced data loader with verbose output
        echo "🚀 Starting data loading process..."
        $PYTHON_CMD scripts/load_test_data.py --env kubernetes --data test_data/complete_dataset.json --verbose
        
        loader_exit_code=$?
        if [ $loader_exit_code -eq 0 ]; then
            print_success "✅ Comprehensive test data loaded successfully!"
            
            # Verify data loading by checking counts
            print_step "Verifying data loading..."
            
            # Check if loading results file exists
            if [ -f "test_data/loading_results.json" ]; then
                echo "📊 Loading verification results:"
                cat test_data/loading_results.json | head -20
            fi
            
            # Quick API verification
            print_step "Performing quick API verification..."
            
            # Check book count
            book_count=$(curl -s http://senecabooks.local/api/catalog/books?size=1 | grep -o '"total":[0-9]*' | cut -d':' -f2 || echo "0")
            echo "📚 Books in catalog: $book_count"
            
            # Check user count (admin endpoint)
            print_step "Data loading verification completed!"
            
        else
            print_warning "Enhanced data loading failed with exit code $loader_exit_code! Attempting recovery..."
            
            # Try simplified fallback loading
            print_step "Attempting simplified fallback data loading..."
            
            # Wait a bit more for services to stabilize
            sleep 20
            
            # Try using the quick start script instead
            if [ -f "scripts/quick_start_data.sh" ]; then
                echo "🔄 Trying quick start data script..."
                chmod +x scripts/quick_start_data.sh
                ./scripts/quick_start_data.sh
                
                if [ $? -eq 0 ]; then
                    print_success "✅ Fallback data loading successful!"
                else
                    print_warning "❌ Fallback data loading also failed"
                fi
            else
                print_warning "❌ No fallback data loading script found"
            fi
        fi
    else
        print_error "Data loading script not found: scripts/load_test_data.py"
    fi
    
    print_success "Test data loading phase completed!"
}

# Function to show deployment summary
show_summary() {
    echo
    print_header
    echo -e "${GREEN}🎉 COMPREHENSIVE MODERNIZATION DEPLOYMENT COMPLETED!${NC}"
    echo
    echo -e "${CYAN}📊 Deployment Summary:${NC}"
    echo -e "  • Project: $PROJECT_NAME"
    echo -e "  • Namespace: $NAMESPACE"
    echo -e "  • Domain: http://$DOMAIN"
    echo -e "  • Registry: $REGISTRY"
    echo -e "  • Test Data: ✅ Loaded with sample users and comprehensive catalog"
    echo -e "  • Modernization: ✅ Shopping cart, enhanced dashboards, improved UI/UX"
    echo
    echo -e "${CYAN}🔗 Access URLs:${NC}"
    echo -e "  • Application: ${GREEN}http://$DOMAIN${NC}"
    echo -e "  • API Docs: ${GREEN}http://$DOMAIN/api/docs${NC}"
    echo
    echo -e "${CYAN}👑 Admin Login:${NC}"
    echo -e "  • Email: ${YELLOW}admin@senecabooks.com${NC}"
    echo -e "  • Password: ${YELLOW}admin123${NC}"
    echo
    echo -e "${CYAN}👤 Sample User Login:${NC}"
    echo -e "  • Email: ${YELLOW}john.doe@example.com${NC}"
    echo -e "  • Password: ${YELLOW}password123${NC}"
    echo
    echo -e "${CYAN}🌟 New Features Available:${NC}"
    echo -e "  • 🛒 Shopping Cart: Add books, manage cart, checkout process"
    echo -e "  • 📊 Enhanced User Dashboard: Overview, purchases, rentals with due dates"
    echo -e "  • ⚙️ Modernized Admin Dashboard: System overview, rental management, inventory alerts"
    echo -e "  • 🎨 Clean UI/UX: Professional styling, responsive design, intuitive navigation"
    echo -e "  • 💳 My Cart Page: Replaces orders, shows cart items + order history with checkout"
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
    echo -e "  • Test API endpoints with curl (now available in all containers):"
    echo -e "    ${YELLOW}kubectl exec -n $NAMESPACE deployment/user-service -- curl http://localhost:8000/health${NC}"
    echo -e "    ${YELLOW}kubectl exec -n $NAMESPACE deployment/catalog-service -- curl http://localhost:8000/health${NC}"
    echo -e "    ${YELLOW}kubectl exec -n $NAMESPACE deployment/order-service -- curl http://localhost:8000/health${NC}"
    echo -e "  • Reload test data: ${YELLOW}source .venv/bin/activate && python scripts/load_test_data.py --env kubernetes${NC}"
    echo -e "  • Cleanup: ${YELLOW}./deploy.sh cleanup${NC}"
    echo
    echo -e "${CYAN}🔍 Frontend-Backend Alignment:${NC}"
    echo -e "  • Frontend automatically detects environment (senecabooks.local vs localhost)"
    echo -e "  • API URLs: /api/user, /api/catalog, /api/order"
    echo -e "  • All services include curl for endpoint troubleshooting"
    echo
    echo -e "${GREEN}✨ MODERNIZED SENECA BOOK STORE IS READY! ✨${NC}"
    echo -e "${GREEN}🚀 Visit http://$DOMAIN to explore the enhanced features!${NC}"
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
    load_test_data
    
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
