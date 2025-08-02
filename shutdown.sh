#!/bin/bash

# 🛑 Seneca Book Store - Kubernetes Shutdown Script
# This script safely shuts down the application while preserving data

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
NAMESPACE="seneca-bookstore"
DOMAIN="senecabooks.local"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}   Seneca Book Store Shutdown Script    ${NC}"
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

# Function to backup databases
backup_data() {
    print_step "Backing up database data..."
    
    local backup_dir="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Check if namespace exists
    if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        print_warning "Namespace $NAMESPACE does not exist, skipping backup"
        return
    fi
    
    local services=("user-service" "catalog-service" "order-service")
    local databases=("users.db" "catalog.db" "orders.db")
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local db="${databases[$i]}"
        
        print_status "Backing up $service database..."
        
        # Check if deployment exists
        if kubectl get deployment $service -n $NAMESPACE >/dev/null 2>&1; then
            # Copy database from pod to local backup directory
            local pod=$(kubectl get pods -n $NAMESPACE -l app=$service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            
            if [ -n "$pod" ]; then
                kubectl cp $NAMESPACE/$pod:/data/$db "$backup_dir/$db" 2>/dev/null || print_warning "Failed to backup $db"
                print_success "$service database backed up"
            else
                print_warning "No running pod found for $service"
            fi
        else
            print_warning "Deployment $service not found"
        fi
    done
    
    if [ "$(ls -A $backup_dir 2>/dev/null)" ]; then
        print_success "Database backup completed: $backup_dir"
        echo -e "${GREEN}💾 Backup location: $backup_dir${NC}"
        
        # Create backup metadata
        cat > "$backup_dir/backup_info.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "environment": "kubernetes",
    "namespace": "$NAMESPACE",
    "files": [
        $(ls -1 "$backup_dir"/*.db 2>/dev/null | xargs -I {} basename {} | sed 's/.*/"&"/' | paste -sd,)
    ]
}
EOF
        
    else
        print_warning "No data was backed up"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Function to check persistent data status
check_persistent_data() {
    print_step "Checking persistent data status..."
    
    # Check if PVC exists
    if kubectl get pvc bookstore-data-pvc -n $NAMESPACE >/dev/null 2>&1; then
        local pvc_status=$(kubectl get pvc bookstore-data-pvc -n $NAMESPACE -o jsonpath='{.status.phase}')
        print_status "PVC Status: $pvc_status"
        
        # Check data directory on minikube
        if minikube ssh -- "[ -d /data/seneca-bookstore ]" 2>/dev/null; then
            local file_count=$(minikube ssh -- "ls -la /data/seneca-bookstore/ 2>/dev/null | wc -l" 2>/dev/null || echo "0")
            print_status "Data directory exists with $file_count files"
            
            # List database files
            minikube ssh -- "ls -lah /data/seneca-bookstore/*.db 2>/dev/null" | while read line; do
                print_status "  $line"
            done || print_status "  No database files found"
        else
            print_warning "Data directory does not exist on minikube"
        fi
    else
        print_warning "No persistent volume claim found"
    fi
}

# Function to scale down deployments gracefully
scale_down_deployments() {
    print_step "Scaling down deployments gracefully..."
    
    if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        print_warning "Namespace $NAMESPACE does not exist"
        return
    fi
    
    local deployments=("frontend-service" "order-service" "catalog-service" "user-service")
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment $deployment -n $NAMESPACE >/dev/null 2>&1; then
            print_status "Scaling down $deployment..."
            kubectl scale deployment $deployment --replicas=0 -n $NAMESPACE
            
            # Wait for pods to terminate
            print_status "Waiting for $deployment pods to terminate..."
            kubectl wait --for=delete pod -l app=$deployment -n $NAMESPACE --timeout=60s || print_warning "Timeout waiting for $deployment pods"
            
            print_success "$deployment scaled down"
        else
            print_warning "Deployment $deployment not found"
        fi
    done
    
    print_success "All deployments scaled down!"
}

# Function to delete Kubernetes resources (preserving data)
cleanup_k8s_resources() {
    print_step "Cleaning up Kubernetes resources..."
    
    if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        print_warning "Namespace $NAMESPACE does not exist"
        return
    fi
    
    # Delete in reverse order of creation, but preserve PVCs
    print_status "Deleting ingress..."
    kubectl delete ingress --all -n $NAMESPACE --ignore-not-found=true
    
    print_status "Deleting services..."
    kubectl delete services --all -n $NAMESPACE --ignore-not-found=true
    
    print_status "Deleting deployments..."
    kubectl delete deployments --all -n $NAMESPACE --ignore-not-found=true
    
    print_status "Deleting certificates..."
    kubectl delete certificates --all -n $NAMESPACE --ignore-not-found=true
    
    print_status "Deleting configmaps..."
    kubectl delete configmaps --all -n $NAMESPACE --ignore-not-found=true
    
    print_status "Deleting secrets..."
    kubectl delete secrets --all -n $NAMESPACE --ignore-not-found=true
    
    # Ask user if they want to delete persistent data
    echo
    print_warning "⚠️  Data Preservation Notice:"
    echo "Persistent Volume Claims (PVCs) contain your database data."
    echo "Deleting them will permanently remove all application data."
    echo
    read -p "Do you want to delete persistent data? [y/N]: " delete_data
    
    if [[ $delete_data =~ ^[Yy]$ ]]; then
        print_status "Deleting persistent volume claims..."
        kubectl delete pvc --all -n $NAMESPACE --ignore-not-found=true
        
        print_status "Deleting persistent volumes..."
        kubectl delete pv bookstore-data-pv --ignore-not-found=true
        
        print_warning "🗑️  All persistent data has been deleted!"
    else
        print_success "💾 Persistent data preserved"
        echo "   PVCs will be reused when you redeploy the application"
    fi
    
    print_success "Kubernetes resources cleaned up!"
}

# Function to delete namespace
delete_namespace() {
    print_step "Deleting namespace..."
    
    if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        kubectl delete namespace $NAMESPACE
        
        print_status "Waiting for namespace deletion..."
        while kubectl get namespace $NAMESPACE >/dev/null 2>&1; do
            sleep 2
            echo -n "."
        done
        echo
        
        print_success "Namespace deleted!"
    else
        print_warning "Namespace $NAMESPACE does not exist"
    fi
}

# Function to remove hosts entry
cleanup_hosts() {
    print_step "Cleaning up hosts file..."
    
    if grep -q "$DOMAIN" /etc/hosts; then
        print_status "Removing hosts entry for $DOMAIN..."
        sudo sed -i "/$DOMAIN/d" /etc/hosts
        print_success "Hosts entry removed"
    else
        print_warning "No hosts entry found for $DOMAIN"
    fi
}

# Function to stop port forwarding
stop_port_forwarding() {
    print_step "Stopping port forwarding processes..."
    
    # Kill any kubectl port-forward processes
    local pids=$(pgrep -f "kubectl.*port-forward" 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        print_status "Stopping port forwarding processes..."
        echo $pids | xargs kill 2>/dev/null || true
        print_success "Port forwarding stopped"
    else
        print_status "No port forwarding processes found"
    fi
}

# Function to stop Minikube
stop_minikube() {
    print_step "Stopping Minikube..."
    
    if ! command_exists minikube; then
        print_warning "Minikube not found"
        return
    fi
    
    if minikube status >/dev/null 2>&1; then
        print_status "Stopping Minikube cluster..."
        minikube stop
        print_success "Minikube stopped"
    else
        print_warning "Minikube is not running"
    fi
}

# Function to delete Minikube
delete_minikube() {
    print_step "Deleting Minikube cluster..."
    
    if ! command_exists minikube; then
        print_warning "Minikube not found"
        return
    fi
    
    echo
    print_warning "⚠️  Minikube Deletion Notice:"
    echo "This will permanently delete the entire Minikube cluster."
    echo "All cluster data and configurations will be lost."
    echo
    read -p "Do you want to delete the Minikube cluster? [y/N]: " delete_minikube
    
    if [[ $delete_minikube =~ ^[Yy]$ ]]; then
        minikube delete
        print_success "Minikube cluster deleted"
    else
        print_status "Minikube cluster preserved"
    fi
}

# Function to show shutdown options
show_help() {
    echo "Seneca Book Store - Kubernetes Shutdown Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  soft       - Soft shutdown (scale down, preserve everything)"
    echo "  app        - Remove application (preserve Minikube and data)"
    echo "  full       - Full shutdown (remove app, stop Minikube, preserve data)"
    echo "  clean      - Clean shutdown (remove everything including data)"
    echo "  backup     - Backup databases only"
    echo "  help       - Show this help message"
    echo
    echo "Shutdown Levels:"
    echo "  🟢 soft:   Scale down pods, keep everything else"
    echo "  🟡 app:    Remove application, keep Minikube running"
    echo "  🟠 full:   Remove app + stop Minikube (preserve data)"
    echo "  🔴 clean:  Remove everything including databases"
    echo
    echo "Examples:"
    echo "  $0 soft     # Quick shutdown, easy restart"
    echo "  $0 app      # Remove app, keep Minikube for other projects"
    echo "  $0 full     # Complete shutdown but preserve data"
    echo "  $0 backup   # Backup databases only"
}

# Function for soft shutdown
soft_shutdown() {
    print_header
    print_status "🟢 Performing soft shutdown..."
    echo "This will scale down all deployments but preserve everything else."
    echo
    
    backup_data
    scale_down_deployments
    stop_port_forwarding
    
    print_success "✅ Soft shutdown completed!"
    echo
    print_status "To restart the application:"
    echo "  ./deploy-k8s.sh apply"
}

# Function for app removal
app_shutdown() {
    print_header
    print_status "🟡 Removing application..."
    echo "This will remove the application but keep Minikube running."
    echo
    
    backup_data
    scale_down_deployments
    cleanup_k8s_resources
    delete_namespace
    cleanup_hosts
    stop_port_forwarding
    
    print_success "✅ Application removed!"
    echo
    print_status "Minikube is still running for other projects."
    print_status "To restart the application:"
    echo "  ./deploy-k8s.sh deploy"
}

# Function for full shutdown
full_shutdown() {
    print_header
    print_status "🟠 Performing full shutdown..."
    echo "This will remove the application and stop Minikube."
    echo
    
    backup_data
    scale_down_deployments
    cleanup_k8s_resources
    delete_namespace
    cleanup_hosts
    stop_port_forwarding
    stop_minikube
    
    print_success "✅ Full shutdown completed!"
    echo
    print_status "To restart everything:"
    echo "  ./deploy-k8s.sh deploy"
}

# Function for clean shutdown
clean_shutdown() {
    print_header
    print_status "🔴 Performing clean shutdown..."
    echo "⚠️  WARNING: This will remove EVERYTHING including databases!"
    echo
    read -p "Are you sure you want to proceed? [y/N]: " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status "Shutdown cancelled"
        exit 0
    fi
    
    # Don't backup if doing clean shutdown - user wants everything gone
    scale_down_deployments
    cleanup_k8s_resources
    delete_namespace
    cleanup_hosts
    stop_port_forwarding
    delete_minikube
    
    # Clean up local backup directories if they exist
    if [ -d "./backups" ]; then
        read -p "Do you want to delete local backups too? [y/N]: " delete_backups
        if [[ $delete_backups =~ ^[Yy]$ ]]; then
            rm -rf "./backups"
            print_success "Local backups deleted"
        fi
    fi
    
    print_success "✅ Clean shutdown completed!"
    echo
    print_status "Everything has been removed."
    print_status "To start fresh:"
    echo "  ./deploy-k8s.sh deploy"
}

# Function to display current status
show_status() {
    print_header
    print_status "📊 Current Status"
    echo
    
    # Check Minikube status
    if command_exists minikube; then
        print_status "🐳 Minikube Status:"
        if minikube status >/dev/null 2>&1; then
            minikube status
        else
            echo "  Minikube is not running"
        fi
    else
        echo "  Minikube not installed"
    fi
    echo
    
    # Check namespace
    if command_exists kubectl; then
        print_status "📦 Application Status:"
        if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
            echo "  Namespace: $NAMESPACE (exists)"
            kubectl get pods -n $NAMESPACE 2>/dev/null || echo "  No pods found"
        else
            echo "  Namespace: $NAMESPACE (not found)"
        fi
    else
        echo "  kubectl not installed"
    fi
    echo
    
    # Check hosts file
    print_status "🌐 Hosts Configuration:"
    if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
        echo "  $DOMAIN is configured in /etc/hosts"
    else
        echo "  $DOMAIN is not configured in /etc/hosts"
    fi
    echo
    
    # Check backups
    print_status "💾 Backup Status:"
    if [ -d "./backups" ] && [ "$(ls -A ./backups 2>/dev/null)" ]; then
        echo "  Local backups found:"
        ls -la ./backups/ | tail -n +2 | awk '{print "    " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'
    else
        echo "  No local backups found"
    fi
}

# Main script logic
case "${1:-help}" in
    soft)
        check_persistent_data
        echo
        soft_shutdown
        ;;
    app)
        check_persistent_data
        echo
        app_shutdown
        ;;
    full)
        check_persistent_data
        echo
        full_shutdown
        ;;
    clean)
        check_persistent_data
        echo
        clean_shutdown
        ;;
    backup)
        backup_data
        ;;
    status)
        show_status
        check_persistent_data
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
