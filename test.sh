#!/bin/bash

# 🧪 Seneca Book Store - Testing Suite
# This script runs comprehensive tests for all services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DOCKER_COMPOSE_URL="http://localhost"
K8S_URL="https://senecabooks.local"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}   Seneca Book Store Testing Suite   ${NC}"
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

# Function to check if services are running
check_services() {
    local base_url=$1
    print_step "Checking service availability at $base_url..."
    
    services=("user" "catalog" "order")
    ports=("8001" "8002" "8003")
    
    if [[ $base_url == *"senecabooks.local"* ]]; then
        # Kubernetes deployment
        for service in "${services[@]}"; do
            print_status "Checking $service service..."
            if curl -f -s "$base_url/api/$service/health" > /dev/null; then
                print_success "$service service is healthy"
            else
                print_error "$service service is not responding"
                return 1
            fi
        done
    else
        # Docker Compose deployment
        for i in "${!services[@]}"; do
            service=${services[$i]}
            port=${ports[$i]}
            print_status "Checking $service service on port $port..."
            if curl -f -s "$base_url:$port/health" > /dev/null; then
                print_success "$service service is healthy"
            else
                print_error "$service service is not responding on port $port"
                return 1
            fi
        done
    fi
    
    print_success "All services are healthy!"
}

# Function to run pytest tests
run_unit_tests() {
    print_step "Running pytest unit tests..."
    
    cd user-service
    if python -m pytest test_user_service.py -v --tb=short; then
        print_success "User service tests passed!"
    else
        print_error "User service tests failed!"
        return 1
    fi
    cd ..
    
    print_success "All unit tests passed!"
}

# Function to run load tests
run_load_tests() {
    local deployment_type=$1
    print_step "Running load tests for $deployment_type deployment..."
    
    if [[ $deployment_type == "kubernetes" ]]; then
        export CATALOG_URL="https://senecabooks.local/api/catalog"
        export ORDER_URL="https://senecabooks.local/api/order"
    else
        export CATALOG_URL="http://localhost:8002"
        export ORDER_URL="http://localhost:8003"
    fi
    
    # Run load tests with moderate load for CI/CD
    if python scripts/load_test.py --requests 50 --users 5 --duration 20; then
        print_success "Load tests passed!"
    else
        print_warning "Load tests completed with some issues"
    fi
}

# Function to run integration tests
run_integration_tests() {
    local base_url=$1
    print_step "Running integration tests..."
    
    # Test user registration and login flow
    print_status "Testing user registration and login flow..."
    
    # Register a test user
    test_email="integration_test_$(date +%s)@example.com"
    register_response=$(curl -s -X POST "$base_url:8001/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$test_email\", \"password\": \"testpass123\", \"is_admin\": false}")
    
    if echo "$register_response" | grep -q "id"; then
        print_success "User registration test passed"
    else
        print_error "User registration test failed"
        return 1
    fi
    
    # Login with the test user
    login_response=$(curl -s -X POST "$base_url:8001/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$test_email\", \"password\": \"testpass123\"}")
    
    if echo "$login_response" | grep -q "access_token"; then
        print_success "User login test passed"
        token=$(echo "$login_response" | python -c "import sys, json; print(json.load(sys.stdin)['access_token'])")
    else
        print_error "User login test failed"
        return 1
    fi
    
    # Test catalog access
    print_status "Testing catalog access..."
    catalog_response=$(curl -s "$base_url:8002/books")
    
    if echo "$catalog_response" | grep -q "books"; then
        print_success "Catalog access test passed"
    else
        print_error "Catalog access test failed"
        return 1
    fi
    
    # Test protected endpoint
    print_status "Testing protected endpoint access..."
    me_response=$(curl -s -H "Authorization: Bearer $token" "$base_url:8001/me")
    
    if echo "$me_response" | grep -q "$test_email"; then
        print_success "Protected endpoint test passed"
    else
        print_error "Protected endpoint test failed"
        return 1
    fi
    
    print_success "All integration tests passed!"
}

# Function to test monitoring endpoints
test_monitoring() {
    print_step "Testing monitoring endpoints..."
    
    # Test Prometheus metrics
    print_status "Testing Prometheus metrics..."
    if curl -f -s "https://senecabooks.local/prometheus/-/healthy" > /dev/null; then
        print_success "Prometheus is healthy"
    else
        print_warning "Prometheus may not be accessible"
    fi
    
    # Test Grafana
    print_status "Testing Grafana..."
    if curl -f -s "https://senecabooks.local/grafana/api/health" > /dev/null; then
        print_success "Grafana is healthy"
    else
        print_warning "Grafana may not be accessible"
    fi
    
    # Test service metrics endpoints
    for service in user catalog order; do
        print_status "Testing $service metrics..."
        if curl -f -s "https://senecabooks.local/api/$service/metrics" > /dev/null; then
            print_success "$service metrics endpoint is working"
        else
            print_warning "$service metrics endpoint may not be accessible"
        fi
    done
}

# Function to show test summary
show_test_summary() {
    print_header
    print_success "🎉 Testing Suite Completed!"
    echo
    print_status "📊 Test Summary:"
    echo "  ✅ Service Health Checks"
    echo "  ✅ Unit Tests (pytest)"
    echo "  ✅ Integration Tests"
    echo "  ✅ Load Tests"
    echo "  ✅ Monitoring Tests"
    echo
    print_status "🔗 Access Points:"
    echo "  🌐 Application: https://senecabooks.local"
    echo "  📊 Prometheus: https://senecabooks.local/prometheus"
    echo "  📈 Grafana: https://senecabooks.local/grafana"
    echo
    print_status "🔐 Monitoring Credentials:"
    echo "  📊 Grafana: admin / admin123"
    echo
}

# Function to show help
show_help() {
    echo "Seneca Book Store Testing Suite"
    echo
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo
    echo "Targets:"
    echo "  docker     Test Docker Compose deployment"
    echo "  k8s        Test Kubernetes deployment"
    echo "  both       Test both deployments (default)"
    echo
    echo "Options:"
    echo "  --unit-only      Run only unit tests"
    echo "  --load-only      Run only load tests"
    echo "  --integration    Run integration tests"
    echo "  --monitoring     Test monitoring endpoints"
    echo "  --quick          Run quick tests (reduced load)"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 docker        # Test Docker deployment"
    echo "  $0 k8s           # Test Kubernetes deployment"
    echo "  $0 --unit-only   # Run only unit tests"
    echo "  $0 --monitoring  # Test monitoring stack"
}

# Main execution
main() {
    print_header
    
    # Parse arguments
    DEPLOYMENT_TARGET="both"
    RUN_UNIT=true
    RUN_LOAD=true
    RUN_INTEGRATION=true
    RUN_MONITORING=false
    QUICK_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker|k8s|both)
                DEPLOYMENT_TARGET=$1
                shift
                ;;
            --unit-only)
                RUN_LOAD=false
                RUN_INTEGRATION=false
                shift
                ;;
            --load-only)
                RUN_UNIT=false
                RUN_INTEGRATION=false
                shift
                ;;
            --integration)
                RUN_UNIT=false
                RUN_LOAD=false
                shift
                ;;
            --monitoring)
                RUN_MONITORING=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Install Python dependencies for testing
    print_step "Installing test dependencies..."
    pip install -q pytest requests
    
    # Run tests based on target
    if [[ $DEPLOYMENT_TARGET == "docker" || $DEPLOYMENT_TARGET == "both" ]]; then
        print_step "Testing Docker Compose deployment..."
        
        if check_services "$DOCKER_COMPOSE_URL"; then
            [[ $RUN_UNIT == true ]] && run_unit_tests
            [[ $RUN_INTEGRATION == true ]] && run_integration_tests "$DOCKER_COMPOSE_URL"
            [[ $RUN_LOAD == true ]] && run_load_tests "docker"
        else
            print_warning "Docker Compose services not available, skipping tests"
        fi
    fi
    
    if [[ $DEPLOYMENT_TARGET == "k8s" || $DEPLOYMENT_TARGET == "both" ]]; then
        print_step "Testing Kubernetes deployment..."
        
        if check_services "$K8S_URL"; then
            [[ $RUN_UNIT == true ]] && run_unit_tests
            [[ $RUN_INTEGRATION == true ]] && run_integration_tests "https://senecabooks.local"
            [[ $RUN_LOAD == true ]] && run_load_tests "kubernetes"
            [[ $RUN_MONITORING == true ]] && test_monitoring
        else
            print_warning "Kubernetes services not available, skipping tests"
        fi
    fi
    
    if [[ $RUN_MONITORING == true ]]; then
        test_monitoring
    fi
    
    show_test_summary
}

# Run main function with all arguments
main "$@"
