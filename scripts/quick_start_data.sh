#!/bin/bash

# 🚀 Quick Start - Load Test Data for Seneca Book Store
# This script provides a quick way to generate and load comprehensive test data

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}  Seneca Book Store - Test Data Loader  ${NC}"
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to check environment
check_environment() {
    print_step "Detecting environment..."
    
    if kubectl get pods -n seneca-bookstore >/dev/null 2>&1; then
        echo "kubernetes"
    elif docker-compose ps >/dev/null 2>&1; then
        echo "docker"
    else
        echo "unknown"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --env ENV        Target environment (kubernetes|docker|auto)"
    echo "  --generate-only  Only generate test data, don't load"
    echo "  --load-only      Only load existing test data"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Auto-detect environment and load data"
    echo "  $0 --env kubernetes          # Load data to Kubernetes"
    echo "  $0 --env docker              # Load data to Docker Compose"
    echo "  $0 --generate-only           # Only generate test data files"
    echo ""
}

# Function to generate test data
generate_test_data() {
    print_step "Generating comprehensive test data..."
    
    if [ ! -f "scripts/generate_test_data.py" ]; then
        print_warning "Test data generator not found!"
        return 1
    fi
    
    python3 scripts/generate_test_data.py
    
    if [ -f "test_data/complete_dataset.json" ]; then
        print_success "Test data generated successfully!"
        
        # Show data statistics
        python3 -c "
import json
with open('test_data/complete_dataset.json', 'r') as f:
    data = json.load(f)
print(f'📊 Generated: {len(data[\"users\"])} users, {len(data[\"books\"])} books, {len(data[\"orders\"])} orders')
"
        return 0
    else
        print_warning "Test data generation failed!"
        return 1
    fi
}

# Function to load test data
load_test_data() {
    local env=$1
    print_step "Loading test data to $env environment..."
    
    if [ ! -f "scripts/load_test_data.py" ]; then
        print_warning "Test data loader not found!"
        return 1
    fi
    
    if [ ! -f "test_data/complete_dataset.json" ]; then
        print_warning "Test data not found! Generating first..."
        if ! generate_test_data; then
            return 1
        fi
    fi
    
    # Install httpx if needed
    if ! python3 -c "import httpx" >/dev/null 2>&1; then
        print_status "Installing httpx..."
        pip3 install httpx >/dev/null 2>&1 || print_warning "Failed to install httpx"
    fi
    
    python3 scripts/load_test_data.py --env $env
    
    if [ $? -eq 0 ]; then
        print_success "Test data loaded successfully!"
        show_access_info $env
        return 0
    else
        print_warning "Test data loading failed!"
        return 1
    fi
}

# Function to show access information
show_access_info() {
    local env=$1
    
    echo ""
    echo -e "${PURPLE}🎉 Test Data Loading Complete!${NC}"
    echo ""
    
    if [ "$env" = "kubernetes" ]; then
        echo -e "${CYAN}🌐 Application URL:${NC} https://senecabooks.local"
    else
        echo -e "${CYAN}🌐 Application URL:${NC} http://localhost:3000"
    fi
    
    echo ""
    echo -e "${CYAN}👑 Admin Account:${NC}"
    echo "   Email: admin@senecabooks.com"
    echo "   Password: admin123"
    echo ""
    echo -e "${CYAN}👤 Sample User Account:${NC}"
    echo "   Email: john.doe@example.com"
    echo "   Password: password123"
    echo ""
    echo -e "${CYAN}📚 Sample Data Includes:${NC}"
    echo "   • 7 user accounts (2 admin, 5 regular)"
    echo "   • 48 books across 3 categories"
    echo "   • 75 sample orders (purchases & rentals)"
    echo "   • External book integration demo"
    echo ""
    echo -e "${CYAN}📖 Documentation:${NC}"
    echo "   • See TEST_DATA.MD for complete details"
    echo "   • Check test_data/ folder for generated files"
    echo ""
}

# Main script
main() {
    print_header
    
    # Parse command line arguments
    ENV="auto"
    GENERATE_ONLY=false
    LOAD_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env)
                ENV="$2"
                shift 2
                ;;
            --generate-only)
                GENERATE_ONLY=true
                shift
                ;;
            --load-only)
                LOAD_ONLY=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Auto-detect environment if needed
    if [ "$ENV" = "auto" ]; then
        ENV=$(check_environment)
        if [ "$ENV" = "unknown" ]; then
            print_warning "Could not detect environment. Please specify --env kubernetes or --env docker"
            show_usage
            exit 1
        fi
        print_status "Auto-detected environment: $ENV"
    fi
    
    # Validate environment
    if [ "$ENV" != "kubernetes" ] && [ "$ENV" != "docker" ]; then
        print_warning "Invalid environment: $ENV (must be kubernetes or docker)"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "deploy.sh" ] || [ ! -d "scripts" ]; then
        print_warning "Please run this script from the Seneca Book Store root directory"
        exit 1
    fi
    
    # Execute based on options
    if [ "$GENERATE_ONLY" = true ]; then
        generate_test_data
    elif [ "$LOAD_ONLY" = true ]; then
        load_test_data $ENV
    else
        # Generate and load
        if generate_test_data; then
            load_test_data $ENV
        else
            exit 1
        fi
    fi
}

# Run main function
main "$@"
