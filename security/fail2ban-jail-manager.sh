#!/bin/bash

# ====================
# Fail2ban Jail Management Script
# Seneca Book Store - Enable/Disable Custom Jails
# ====================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Enable a specific jail
enable_jail() {
    local jail_name=$1
    
    log "Enabling jail: $jail_name"
    
    # Update configuration
    sed -i "/^\[$jail_name\]/,/^\[/ s/enabled = false/enabled = true/" /etc/fail2ban/jail.local
    
    # Reload fail2ban
    systemctl reload fail2ban
    
    # Wait and check status
    sleep 2
    if fail2ban-client status | grep -q "$jail_name"; then
        log "Jail $jail_name enabled successfully"
    else
        warn "Failed to enable jail $jail_name"
    fi
}

# Disable a specific jail
disable_jail() {
    local jail_name=$1
    
    log "Disabling jail: $jail_name"
    
    # Stop the jail first
    fail2ban-client stop "$jail_name" 2>/dev/null || true
    
    # Update configuration
    sed -i "/^\[$jail_name\]/,/^\[/ s/enabled = true/enabled = false/" /etc/fail2ban/jail.local
    
    # Reload fail2ban
    systemctl reload fail2ban
    
    log "Jail $jail_name disabled"
}

# Enable web protection jails
enable_web_protection() {
    log "Enabling web protection jails..."
    
    # Check if nginx is installed and running
    if systemctl is-active --quiet nginx; then
        enable_jail "nginx-http-auth"
        enable_jail "nginx-limit-req"
        enable_jail "nginx-botsearch"
    else
        warn "Nginx is not running. Web protection jails will remain disabled."
        echo "To enable web protection later, run:"
        echo "  sudo $0 enable nginx-http-auth"
        echo "  sudo $0 enable nginx-limit-req"
        echo "  sudo $0 enable nginx-botsearch"
    fi
}

# Enable application protection jails
enable_app_protection() {
    log "Enabling application protection jails..."
    
    # Check if application logs exist and have content
    if [[ -s /var/log/seneca-bookstore/auth.log ]] || [[ -s /var/log/seneca-bookstore/user-service.log ]]; then
        enable_jail "seneca-auth-failure"
        enable_jail "seneca-api-abuse"
    else
        warn "Application logs are empty. Application protection jails will remain disabled."
        echo "Application jails will be automatically enabled when your services start logging."
        echo "To enable manually later, run:"
        echo "  sudo $0 enable seneca-auth-failure"
        echo "  sudo $0 enable seneca-api-abuse"
    fi
}

# Enable Docker protection
enable_docker_protection() {
    log "Enabling Docker protection jail..."
    
    # Check if Docker registry is running
    if docker ps | grep -q registry || [[ -s /var/log/docker-registry/auth.log ]]; then
        enable_jail "docker-auth"
    else
        warn "Docker registry not detected. Docker protection jail will remain disabled."
        echo "To enable Docker protection later, run:"
        echo "  sudo $0 enable docker-auth"
    fi
}

# Show current jail status
show_status() {
    echo -e "${BLUE}=== Current Jail Status ===${NC}"
    fail2ban-client status
    echo
    
    echo -e "${BLUE}=== Individual Jail Details ===${NC}"
    for jail in $(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$'); do
        echo "--- $jail ---"
        fail2ban-client status "$jail" | grep -E "(Currently|Total)"
        echo
    done
}

# Test jail configuration
test_jail() {
    local jail_name=$1
    
    log "Testing jail configuration: $jail_name"
    
    # Test the filter
    local filter_file="/etc/fail2ban/filter.d/${jail_name}.conf"
    if [[ -f "$filter_file" ]]; then
        log "Filter file exists: $filter_file"
    else
        warn "Filter file not found: $filter_file"
    fi
    
    # Test log file access
    local config_section=$(awk "/^\[$jail_name\]/,/^\[/" /etc/fail2ban/jail.local)
    local logpaths=$(echo "$config_section" | grep "logpath" | cut -d= -f2 | tr -d ' ')
    
    for logpath in $logpaths; do
        if [[ -f "$logpath" ]]; then
            log "Log file accessible: $logpath"
            if [[ -r "$logpath" ]]; then
                log "Log file readable: $logpath"
            else
                warn "Log file not readable: $logpath"
            fi
        else
            warn "Log file not found: $logpath"
        fi
    done
}

# List available jails
list_jails() {
    echo -e "${BLUE}=== Available Jails ===${NC}"
    echo
    echo "Active jails:"
    fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$' | while read jail; do
        echo "  ✓ $jail (enabled)"
    done
    echo
    echo "Available jails in configuration:"
    grep "^\[.*\]" /etc/fail2ban/jail.local | tr -d '[]' | grep -v "DEFAULT" | while read jail; do
        if fail2ban-client status | grep -q "$jail"; then
            echo "  ✓ $jail (enabled)"
        else
            echo "  ○ $jail (disabled)"
        fi
    done
}

# Main function
main() {
    check_root
    
    case "${1:-help}" in
        enable)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 enable <jail_name>"
                exit 1
            fi
            enable_jail "$2"
            ;;
        disable)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 disable <jail_name>"
                exit 1
            fi
            disable_jail "$2"
            ;;
        enable-web)
            enable_web_protection
            ;;
        enable-app)
            enable_app_protection
            ;;
        enable-docker)
            enable_docker_protection
            ;;
        enable-all)
            enable_web_protection
            enable_app_protection
            enable_docker_protection
            ;;
        status)
            show_status
            ;;
        list)
            list_jails
            ;;
        test)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 test <jail_name>"
                exit 1
            fi
            test_jail "$2"
            ;;
        help|*)
            echo "Seneca Book Store Fail2ban Jail Manager"
            echo
            echo "Usage: $0 <command> [args]"
            echo
            echo "Commands:"
            echo "  enable <jail>     Enable specific jail"
            echo "  disable <jail>    Disable specific jail"
            echo "  enable-web        Enable web protection jails"
            echo "  enable-app        Enable application protection jails"
            echo "  enable-docker     Enable Docker protection jail"
            echo "  enable-all        Enable all available protection jails"
            echo "  status            Show current jail status"
            echo "  list              List all available jails"
            echo "  test <jail>       Test jail configuration"
            echo "  help              Show this help message"
            echo
            echo "Examples:"
            echo "  $0 enable nginx-http-auth"
            echo "  $0 enable-web"
            echo "  $0 status"
            echo "  $0 test seneca-auth-failure"
            ;;
    esac
}

main "$@"
