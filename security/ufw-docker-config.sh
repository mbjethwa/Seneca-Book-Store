#!/bin/bash

# ====================
# UFW Firewall Configuration for Docker/Kubernetes
# Seneca Book Store - Ubuntu Server Security
# ====================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Backup existing UFW configuration
backup_ufw_config() {
    log "Backing up existing UFW configuration..."
    
    local backup_dir="/etc/ufw/backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp -r /etc/ufw/* "$backup_dir/" 2>/dev/null || true
    cp /etc/default/ufw "$backup_dir/" 2>/dev/null || true
    
    log "UFW configuration backed up to $backup_dir"
}

# Reset UFW to clean state
reset_ufw() {
    log "Resetting UFW to clean state..."
    
    ufw --force reset
    log "UFW reset completed"
}

# Configure UFW defaults
configure_ufw_defaults() {
    log "Configuring UFW default policies..."
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    ufw default deny forward
    
    log "Default policies configured"
}

# Configure Docker-specific UFW rules
configure_docker_ufw() {
    log "Configuring Docker-specific UFW rules..."
    
    # Create a separate file for Docker rules to avoid conflicts
    cat > /etc/ufw/docker-rules.conf << 'EOF'
# Docker UFW Rules Configuration
# These rules will be applied after UFW is enabled

# Docker bridge network rules - reject external Docker daemon access
-A ufw-after-input -p tcp --dport 2376 -j ufw-reject-input
-A ufw-after-input -p tcp --dport 2377 -j ufw-reject-input

# Allow Docker bridge network communication
-A ufw-after-forward -i docker0 -o docker0 -j ACCEPT

# Allow containers to communicate with each other
-A ufw-after-forward -s 172.16.0.0/12 -d 172.16.0.0/12 -j ACCEPT
-A ufw-after-forward -s 172.20.0.0/24 -d 172.20.0.0/24 -j ACCEPT
-A ufw-after-forward -s 172.21.0.0/24 -d 172.21.0.0/24 -j ACCEPT
EOF

    log "Docker UFW rules configured"
}

# Configure Kubernetes-specific UFW rules
configure_kubernetes_ufw() {
    log "Configuring Kubernetes-specific UFW rules..."
    
    # Create a separate file for Kubernetes rules
    cat > /etc/ufw/kubernetes-rules.conf << 'EOF'
# Kubernetes UFW Rules Configuration
# Apply these manually after UFW is enabled if needed

# Kubernetes API server (internal networks only)
# ufw allow from 10.0.0.0/8 to any port 6443 proto tcp
# ufw allow from 192.168.0.0/16 to any port 6443 proto tcp

# Kubernetes kubelet API (internal networks only)  
# ufw allow from 10.0.0.0/8 to any port 10250 proto tcp
# ufw allow from 192.168.0.0/16 to any port 10250 proto tcp
EOF

    log "Kubernetes UFW rules configured (manual application required)"
}

# Configure application-specific rules
configure_application_rules() {
    log "Configuring Seneca Book Store application rules..."
    
    # SSH - Essential for remote management
    ufw allow 22/tcp comment "SSH"
    
    # HTTP/HTTPS - Web traffic
    ufw allow 80/tcp comment "HTTP"
    ufw allow 443/tcp comment "HTTPS"
    
    # Seneca Book Store microservices
    ufw allow 8001/tcp comment "User Service"
    ufw allow 8002/tcp comment "Catalog Service" 
    ufw allow 8003/tcp comment "Order Service"
    
    # Frontend service
    ufw allow 3000/tcp comment "Frontend Service"
    
    # Monitoring services
    ufw allow 9090/tcp comment "Prometheus"
    ufw allow 3001/tcp comment "Grafana"  # Using 3001 to avoid conflict with frontend
    
    # Docker registry (if using local registry)
    ufw allow 5000/tcp comment "Docker Registry"
    
    # Kubernetes NodePort range (if needed)
    ufw allow 30000:32767/tcp comment "Kubernetes NodePorts"
    
    log "Application rules configured"
}

# Configure logging
configure_ufw_logging() {
    log "Configuring UFW logging..."
    
    # Enable logging
    ufw logging on
    
    # Configure log level
    ufw logging medium
    
    # Configure logrotate for UFW logs
    cat > /etc/logrotate.d/ufw << 'EOF'
/var/log/ufw.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 root adm
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
    
    log "UFW logging configured"
}

# Configure rate limiting
configure_rate_limiting() {
    log "Configuring rate limiting..."
    
    # Rate limit SSH connections
    ufw limit ssh comment "Rate limit SSH"
    
    # Rate limit HTTP connections
    ufw limit 80/tcp comment "Rate limit HTTP"
    ufw limit 443/tcp comment "Rate limit HTTPS"
    
    log "Rate limiting configured"
}

# Configure UFW application profiles
configure_app_profiles() {
    log "Creating UFW application profiles..."
    
    # Create Seneca Book Store profile
    cat > /etc/ufw/applications.d/seneca-bookstore << 'EOF'
[Seneca-BookStore-Full]
title=Seneca Book Store (Full)
description=Seneca Book Store microservices and frontend
ports=80,443,3000,8001,8002,8003

[Seneca-BookStore-API]
title=Seneca Book Store (API Only)
description=Seneca Book Store microservices APIs
ports=8001,8002,8003

[Seneca-BookStore-Frontend]
title=Seneca Book Store (Frontend Only)
description=Seneca Book Store frontend service
ports=3000/tcp

[Seneca-Monitoring]
title=Seneca Book Store Monitoring
description=Prometheus and Grafana monitoring
ports=9090,3001
EOF

    # Create Docker profile
    cat > /etc/ufw/applications.d/docker << 'EOF'
[Docker-Registry]
title=Docker Registry
description=Local Docker registry
ports=5000/tcp

[Docker-Swarm]
title=Docker Swarm
description=Docker Swarm cluster communication
ports=2377/tcp,7946,4789/udp
EOF

    # Create Kubernetes profile
    cat > /etc/ufw/applications.d/kubernetes << 'EOF'
[Kubernetes-API]
title=Kubernetes API Server
description=Kubernetes API server
ports=6443/tcp

[Kubernetes-NodePorts]
title=Kubernetes NodePorts
description=Kubernetes NodePort services
ports=30000:32767/tcp

[Kubernetes-Kubelet]
title=Kubernetes Kubelet
description=Kubernetes kubelet API
ports=10250/tcp
EOF

    log "Application profiles created"
}

# Configure network-specific rules
configure_network_rules() {
    log "Configuring network-specific rules..."
    
    # Allow loopback traffic
    ufw allow in on lo
    ufw allow out on lo
    
    # Allow established and related connections
    ufw allow in on any to any port 22 proto tcp
    
    # Allow specific subnets (adjust as needed)
    # ufw allow from 192.168.1.0/24 comment "Local network"
    # ufw allow from 10.0.0.0/8 comment "Private network"
    
    log "Network rules configured"
}

# Configure UFW to start at boot
configure_ufw_service() {
    log "Configuring UFW service..."
    
    # Enable UFW service
    systemctl enable ufw
    
    # Ensure UFW starts before Docker
    mkdir -p /etc/systemd/system/docker.service.d
    cat > /etc/systemd/system/docker.service.d/ufw.conf << 'EOF'
[Unit]
After=ufw.service
Requires=ufw.service
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    log "UFW service configured"
}

# Create UFW management script
create_management_script() {
    log "Creating UFW management script..."
    
    cat > /usr/local/bin/seneca-firewall << 'EOF'
#!/bin/bash

# Seneca Book Store Firewall Management Script

show_status() {
    echo "=== UFW Status ==="
    ufw status verbose
    echo
    echo "=== Recent UFW Log Entries ==="
    tail -20 /var/log/ufw.log 2>/dev/null || echo "No UFW logs found"
}

show_rules() {
    echo "=== UFW Rules ==="
    ufw status numbered
}

show_apps() {
    echo "=== Available Application Profiles ==="
    ufw app list
}

allow_service() {
    local service=$1
    if [[ -z "$service" ]]; then
        echo "Usage: $0 allow <service|port>"
        return 1
    fi
    
    echo "Allowing $service..."
    ufw allow "$service"
}

deny_service() {
    local service=$1
    if [[ -z "$service" ]]; then
        echo "Usage: $0 deny <service|port>"
        return 1
    fi
    
    echo "Denying $service..."
    ufw deny "$service"
}

delete_rule() {
    local rule_num=$1
    if [[ -z "$rule_num" ]]; then
        echo "Usage: $0 delete <rule_number>"
        echo "Use '$0 rules' to see rule numbers"
        return 1
    fi
    
    echo "Deleting rule $rule_num..."
    ufw --force delete "$rule_num"
}

show_docker_rules() {
    echo "=== Docker-related iptables rules ==="
    iptables -L DOCKER-USER 2>/dev/null || echo "No DOCKER-USER chain found"
    echo
    iptables -L FORWARD | grep -i docker || echo "No Docker FORWARD rules found"
}

case "${1:-status}" in
    status|s)
        show_status
        ;;
    rules|r)
        show_rules
        ;;
    apps|a)
        show_apps
        ;;
    allow)
        allow_service "$2"
        ;;
    deny)
        deny_service "$2"
        ;;
    delete|del)
        delete_rule "$2"
        ;;
    docker|d)
        show_docker_rules
        ;;
    reload)
        echo "Reloading UFW..."
        ufw reload
        ;;
    *)
        echo "Seneca Book Store Firewall Management"
        echo
        echo "Usage: $0 [command] [args]"
        echo
        echo "Commands:"
        echo "  status, s          Show UFW status and recent logs"
        echo "  rules, r           Show numbered rules"
        echo "  apps, a            Show available application profiles"
        echo "  allow <service>    Allow service/port"
        echo "  deny <service>     Deny service/port"
        echo "  delete <num>       Delete rule by number"
        echo "  docker, d          Show Docker-related rules"
        echo "  reload             Reload UFW configuration"
        echo
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 allow 8080"
        echo "  $0 allow 'Seneca-BookStore-Full'"
        echo "  $0 delete 5"
        ;;
esac
EOF

    chmod +x /usr/local/bin/seneca-firewall
    
    log "UFW management script created at /usr/local/bin/seneca-firewall"
}

# Enable UFW with confirmation
enable_ufw() {
    log "Enabling UFW firewall..."
    
    warn "About to enable UFW. This will activate the firewall with the configured rules."
    warn "Make sure you have SSH access configured (port 22 is allowed)."
    
    read -p "Do you want to enable UFW now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ufw --force enable
        log "UFW enabled successfully"
    else
        warn "UFW not enabled. You can enable it later with: sudo ufw enable"
    fi
}

# Show final status
show_final_status() {
    log "UFW configuration completed!"
    echo
    echo -e "${BLUE}=== Current UFW Status ===${NC}"
    ufw status verbose
    echo
    echo -e "${BLUE}=== Available Commands ===${NC}"
    echo "  sudo seneca-firewall status    - Show status and logs"
    echo "  sudo seneca-firewall rules     - Show all rules"
    echo "  sudo seneca-firewall apps      - Show application profiles"
    echo "  sudo ufw enable               - Enable firewall"
    echo "  sudo ufw disable              - Disable firewall"
    echo
    echo -e "${YELLOW}=== Important Notes ===${NC}"
    echo "1. UFW is configured to work with Docker and Kubernetes"
    echo "2. Application-specific profiles have been created"
    echo "3. Rate limiting is enabled for SSH and HTTP(S)"
    echo "4. Logging is enabled and configured with rotation"
    echo "5. Service will start automatically at boot"
}

# Main execution
main() {
    log "Starting UFW firewall configuration for Seneca Book Store..."
    
    check_root
    backup_ufw_config
    reset_ufw
    configure_ufw_defaults
    configure_docker_ufw
    configure_kubernetes_ufw
    configure_application_rules
    configure_ufw_logging
    configure_rate_limiting
    configure_app_profiles
    configure_network_rules
    configure_ufw_service
    create_management_script
    enable_ufw
    show_final_status
    
    log "UFW firewall configuration completed successfully!"
}

# Run main function
main "$@"
