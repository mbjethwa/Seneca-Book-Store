#!/bin/bash

# ====================
# Fail2ban Configuration for Seneca Book Store
# Ubuntu Server Security - Brute Force Protection
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

# Install Fail2ban if not present
install_fail2ban() {
    log "Checking Fail2ban installation..."
    
    if ! command -v fail2ban-server &> /dev/null; then
        log "Installing Fail2ban..."
        apt-get update
        apt-get install -y fail2ban
        log "Fail2ban installed successfully"
    else
        log "Fail2ban is already installed"
    fi
}

# Backup existing configuration
backup_fail2ban_config() {
    log "Backing up existing Fail2ban configuration..."
    
    local backup_dir="/etc/fail2ban/backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -d "/etc/fail2ban" ]]; then
        cp -r /etc/fail2ban/* "$backup_dir/" 2>/dev/null || true
        log "Fail2ban configuration backed up to $backup_dir"
    fi
}

# Configure main Fail2ban settings
configure_fail2ban_main() {
    log "Configuring main Fail2ban settings..."
    
    cat > /etc/fail2ban/jail.local << 'EOF'
# Fail2ban Configuration for Seneca Book Store
# Custom jail configuration

[DEFAULT]
# Global settings
ignoreip = 127.0.0.1/8 ::1
bantime = 3600
findtime = 600
maxretry = 5
backend = auto
usedns = warn
logencoding = auto
enabled = false

# Email notifications (configure as needed)
destemail = admin@senecabooks.com
sendername = Fail2Ban-SenecaBookStore
mta = sendmail
action = %(action_mw)s

# Ban action
banaction = iptables-multiport
banaction_allports = iptables-allports
chain = INPUT
protocol = tcp

# Log settings
logtarget = /var/log/fail2ban.log

[sshd]
# SSH brute force protection
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
findtime = 300

[sshd-ddos]
# SSH DDOS protection
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2
bantime = 7200
findtime = 120

[nginx-http-auth]
# Nginx HTTP authentication failures
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600
findtime = 600

[nginx-limit-req]
# Nginx rate limiting violations
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 1800
findtime = 300

[nginx-botsearch]
# Nginx bot and vulnerability scanner protection
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400
findtime = 600

[seneca-auth-failure]
# Custom jail for Seneca Book Store authentication failures
enabled = true
port = 8001,8002,8003
filter = seneca-auth-failure
logpath = /var/log/seneca-bookstore/auth.log
          /var/log/seneca-bookstore/user-service.log
          /var/log/seneca-bookstore/catalog-service.log
          /var/log/seneca-bookstore/order-service.log
maxretry = 5
bantime = 7200
findtime = 600

[seneca-api-abuse]
# API abuse protection for microservices
enabled = true
port = 8001,8002,8003
filter = seneca-api-abuse
logpath = /var/log/seneca-bookstore/user-service.log
          /var/log/seneca-bookstore/catalog-service.log
          /var/log/seneca-bookstore/order-service.log
maxretry = 10
bantime = 3600
findtime = 300

[docker-auth]
# Docker registry authentication failures
enabled = true
port = 5000
filter = docker-auth
logpath = /var/log/docker-registry/auth.log
maxretry = 3
bantime = 3600
findtime = 300
EOF

    log "Main Fail2ban configuration completed"
}

# Configure custom filters
configure_custom_filters() {
    log "Configuring custom Fail2ban filters..."
    
    # Seneca Book Store authentication failure filter
    cat > /etc/fail2ban/filter.d/seneca-auth-failure.conf << 'EOF'
# Fail2ban filter for Seneca Book Store authentication failures

[Definition]
# Pattern to match authentication failures in application logs
failregex = ^.*\[.*\] .*Authentication failed.*from <HOST>.*$
            ^.*\[.*\] .*Invalid credentials.*from <HOST>.*$
            ^.*\[.*\] .*Login attempt failed.*from <HOST>.*$
            ^.*\[.*\] .*Unauthorized access.*from <HOST>.*$
            ^.*\[.*\] .*Invalid token.*from <HOST>.*$
            ^.*\[.*\] .*JWT.*invalid.*from <HOST>.*$
            ^.*\[.*\] .*Failed login.*<HOST>.*$

# Ignore successful authentications
ignoreregex = ^.*\[.*\] .*Authentication successful.*$
              ^.*\[.*\] .*Login successful.*$
              ^.*\[.*\] .*User logged in.*$

datepattern = ^%%Y-%%m-%%d[T ]%%H:%%M:%%S
EOF

    # API abuse filter
    cat > /etc/fail2ban/filter.d/seneca-api-abuse.conf << 'EOF'
# Fail2ban filter for Seneca Book Store API abuse

[Definition]
# Pattern to match API abuse attempts
failregex = ^.*\[.*\] .*Rate limit exceeded.*from <HOST>.*$
            ^.*\[.*\] .*Too many requests.*from <HOST>.*$
            ^.*\[.*\] .*API quota exceeded.*from <HOST>.*$
            ^.*\[.*\] .*Blocked suspicious activity.*from <HOST>.*$
            ^.*\[.*\] .*SQL injection attempt.*from <HOST>.*$
            ^.*\[.*\] .*XSS attempt.*from <HOST>.*$
            ^.*\[.*\] .*Path traversal.*from <HOST>.*$

# Ignore normal API usage
ignoreregex = ^.*\[.*\] .*200.*GET.*$
              ^.*\[.*\] .*201.*POST.*$
              ^.*\[.*\] .*Normal request.*$

datepattern = ^%%Y-%%m-%%d[T ]%%H:%%M:%%S
EOF

    # Docker authentication filter
    cat > /etc/fail2ban/filter.d/docker-auth.conf << 'EOF'
# Fail2ban filter for Docker registry authentication failures

[Definition]
# Pattern to match Docker authentication failures
failregex = ^.*\[.*\] .*authentication failed.*<HOST>.*$
            ^.*\[.*\] .*unauthorized.*<HOST>.*$
            ^.*\[.*\] .*invalid credentials.*<HOST>.*$
            ^.*\[.*\] .*access denied.*<HOST>.*$

ignoreregex = ^.*\[.*\] .*authentication successful.*$

datepattern = ^%%Y-%%m-%%d[T ]%%H:%%M:%%S
EOF

    # Enhanced nginx filters
    cat > /etc/fail2ban/filter.d/nginx-botsearch.conf << 'EOF'
# Fail2ban filter for nginx bot and vulnerability scanner protection

[Definition]
# Common bot and scanner patterns
failregex = ^<HOST> -.*"(GET|POST|HEAD).*/(admin|wp-admin|phpMyAdmin|phpmyadmin|mysql|pma|dbadmin|websql|sql|myadmin).*" (404|403|500).*$
            ^<HOST> -.*"(GET|POST|HEAD).*/(\\.git|\\.\\./).*" (404|403|500).*$
            ^<HOST> -.*"(GET|POST|HEAD).*/(.env|config\\.php|wp-config\\.php|settings\\.php).*" (404|403|500).*$
            ^<HOST> -.*"(GET|POST|HEAD).*/(.+\\.(bak|backup|old|orig|tmp|test|dev|log|conf|config)).*" (404|403|500).*$
            ^<HOST> -.*"(GET|POST|HEAD).*/shell.*" (404|403|500).*$

ignoreregex = 

datepattern = ^%%d/%%b/%%Y:%%H:%%M:%%S %%z
EOF

    log "Custom filters configured"
}

# Configure actions
configure_custom_actions() {
    log "Configuring custom Fail2ban actions..."
    
    # Custom action for Seneca Book Store notifications
    cat > /etc/fail2ban/action.d/seneca-notification.conf << 'EOF'
# Custom action for Seneca Book Store security notifications

[Definition]
# Command executed when banning an IP
actionstart = printf %%b "Subject: [Fail2Ban-SenecaBookStore] Started on `uname -n`
              Date: `LC_ALL=C date`
              Hi,
              
              The jail <name> has been started successfully.
              
              Regards,
              Fail2Ban-SenecaBookStore" | /usr/sbin/sendmail <dest>

actionstop = printf %%b "Subject: [Fail2Ban-SenecaBookStore] Stopped on `uname -n`
             Date: `LC_ALL=C date`
             Hi,
             
             The jail <name> has been stopped.
             
             Regards,
             Fail2Ban-SenecaBookStore" | /usr/sbin/sendmail <dest>

actioncheck = 

actionban = printf %%b "Subject: [Fail2Ban-SenecaBookStore] <name>: banned <ip>
            Date: `LC_ALL=C date`
            Hi,
            
            The IP <ip> has just been banned by Fail2Ban after <failures> attempts
            against <name> on `uname -n`.
            
            Here are more information about <ip>:
            `whois <ip> 2>/dev/null | grep -E '^(OrgName|Organization|descr|netname|country):'`
            
            Lines containing IP <ip> in <logpath>:
            `grep -E '(^|[^0-9])<ip>([^0-9]|$)' <logpath> | tail -10`
            
            Regards,
            Fail2Ban-SenecaBookStore" | /usr/sbin/sendmail <dest>

actionunban = printf %%b "Subject: [Fail2Ban-SenecaBookStore] <name>: unbanned <ip>
              Date: `LC_ALL=C date`
              Hi,
              
              The IP <ip> has just been unbanned from <name> on `uname -n`.
              
              Regards,
              Fail2Ban-SenecaBookStore" | /usr/sbin/sendmail <dest>

[Init]
dest = admin@senecabooks.com
EOF

    log "Custom actions configured"
}

# Create log directories
create_log_directories() {
    log "Creating application log directories..."
    
    # Create Seneca Book Store log directory
    mkdir -p /var/log/seneca-bookstore
    mkdir -p /var/log/docker-registry
    mkdir -p /var/log/nginx
    
    # Set proper permissions
    chown -R www-data:adm /var/log/nginx 2>/dev/null || true
    chmod 755 /var/log/seneca-bookstore
    chmod 755 /var/log/docker-registry
    
    # Create placeholder log files
    touch /var/log/seneca-bookstore/auth.log
    touch /var/log/seneca-bookstore/user-service.log
    touch /var/log/seneca-bookstore/catalog-service.log
    touch /var/log/seneca-bookstore/order-service.log
    touch /var/log/docker-registry/auth.log
    
    # Set permissions on log files
    chmod 644 /var/log/seneca-bookstore/*.log
    chmod 644 /var/log/docker-registry/*.log
    
    log "Log directories created"
}

# Configure log rotation
configure_log_rotation() {
    log "Configuring log rotation for Seneca Book Store..."
    
    cat > /etc/logrotate.d/seneca-bookstore << 'EOF'
/var/log/seneca-bookstore/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    sharedscripts
    postrotate
        /bin/systemctl reload fail2ban > /dev/null 2>&1 || true
    endscript
}

/var/log/docker-registry/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    sharedscripts
    postrotate
        /bin/systemctl reload fail2ban > /dev/null 2>&1 || true
    endscript
}
EOF

    cat > /etc/logrotate.d/fail2ban-custom << 'EOF'
/var/log/fail2ban.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        /bin/systemctl reload fail2ban > /dev/null 2>&1 || true
    endscript
}
EOF

    log "Log rotation configured"
}

# Create monitoring script
create_monitoring_script() {
    log "Creating Fail2ban monitoring script..."
    
    cat > /usr/local/bin/seneca-fail2ban-monitor << 'EOF'
#!/bin/bash

# Seneca Book Store Fail2ban Monitoring Script

show_status() {
    echo "=== Fail2ban Status ==="
    systemctl status fail2ban --no-pager
    echo
    
    echo "=== Active Jails ==="
    fail2ban-client status
    echo
    
    echo "=== Jail Details ==="
    for jail in $(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$'); do
        echo "--- $jail ---"
        fail2ban-client status "$jail" 2>/dev/null || echo "Error getting status for $jail"
        echo
    done
}

show_banned_ips() {
    echo "=== Currently Banned IPs ==="
    
    for jail in $(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$'); do
        banned=$(fail2ban-client status "$jail" 2>/dev/null | grep "Banned IP list:" | cut -d: -f2 | tr -d ' ')
        if [[ -n "$banned" ]]; then
            echo "$jail: $banned"
        fi
    done
}

show_recent_bans() {
    echo "=== Recent Ban Activity ==="
    grep "Ban\|Unban" /var/log/fail2ban.log | tail -20
}

unban_ip() {
    local ip=$1
    local jail=${2:-"all"}
    
    if [[ -z "$ip" ]]; then
        echo "Usage: $0 unban <IP> [jail]"
        return 1
    fi
    
    if [[ "$jail" == "all" ]]; then
        echo "Unbanning $ip from all jails..."
        for j in $(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$'); do
            fail2ban-client set "$j" unbanip "$ip" 2>/dev/null && echo "Unbanned from $j"
        done
    else
        echo "Unbanning $ip from $jail..."
        fail2ban-client set "$jail" unbanip "$ip"
    fi
}

ban_ip() {
    local ip=$1
    local jail=${2:-"sshd"}
    
    if [[ -z "$ip" ]]; then
        echo "Usage: $0 ban <IP> [jail]"
        return 1
    fi
    
    echo "Banning $ip in $jail..."
    fail2ban-client set "$jail" banip "$ip"
}

reload_fail2ban() {
    echo "Reloading Fail2ban configuration..."
    systemctl reload fail2ban
    echo "Fail2ban reloaded"
}

test_filters() {
    echo "=== Testing Fail2ban Filters ==="
    
    # Test SSH filter
    echo "Testing SSH filter:"
    fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf --print-all-matched
    
    # Test custom filters if log files exist
    if [[ -f /var/log/seneca-bookstore/auth.log ]]; then
        echo "Testing Seneca auth filter:"
        fail2ban-regex /var/log/seneca-bookstore/auth.log /etc/fail2ban/filter.d/seneca-auth-failure.conf --print-all-matched
    fi
}

show_config() {
    echo "=== Fail2ban Configuration ==="
    echo "Main config: /etc/fail2ban/jail.local"
    echo "Custom filters: /etc/fail2ban/filter.d/seneca-*.conf"
    echo "Custom actions: /etc/fail2ban/action.d/seneca-*.conf"
    echo
    echo "Active configuration:"
    fail2ban-client get all logtarget
    fail2ban-client get all loglevel
}

show_logs() {
    local lines=${1:-50}
    echo "=== Recent Fail2ban Log Entries ==="
    tail -n "$lines" /var/log/fail2ban.log
}

case "${1:-status}" in
    status|s)
        show_status
        ;;
    banned|b)
        show_banned_ips
        ;;
    recent|r)
        show_recent_bans
        ;;
    unban)
        unban_ip "$2" "$3"
        ;;
    ban)
        ban_ip "$2" "$3"
        ;;
    reload)
        reload_fail2ban
        ;;
    test|t)
        test_filters
        ;;
    config|c)
        show_config
        ;;
    logs|l)
        show_logs "$2"
        ;;
    *)
        echo "Seneca Book Store Fail2ban Monitor"
        echo
        echo "Usage: $0 [command] [args]"
        echo
        echo "Commands:"
        echo "  status, s              Show Fail2ban status and jail details"
        echo "  banned, b              Show currently banned IPs"
        echo "  recent, r              Show recent ban/unban activity"
        echo "  unban <ip> [jail]      Unban IP from jail (or all jails)"
        echo "  ban <ip> [jail]        Ban IP in jail (default: sshd)"
        echo "  reload                 Reload Fail2ban configuration"
        echo "  test, t                Test filter patterns"
        echo "  config, c              Show configuration information"
        echo "  logs, l [lines]        Show recent log entries"
        echo
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 banned"
        echo "  $0 unban 192.168.1.100"
        echo "  $0 ban 10.0.0.1 sshd"
        echo "  $0 logs 100"
        ;;
esac
EOF

    chmod +x /usr/local/bin/seneca-fail2ban-monitor
    
    log "Monitoring script created at /usr/local/bin/seneca-fail2ban-monitor"
}

# Configure Fail2ban service
configure_fail2ban_service() {
    log "Configuring Fail2ban service..."
    
    # Enable and start the service
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # Wait for service to start
    sleep 3
    
    # Check if service is running
    if systemctl is-active --quiet fail2ban; then
        log "Fail2ban service is running"
    else
        error "Failed to start Fail2ban service"
    fi
}

# Create integration with UFW
configure_ufw_integration() {
    log "Configuring UFW integration with Fail2ban..."
    
    # Create custom UFW action for Fail2ban
    cat > /etc/fail2ban/action.d/ufw.conf << 'EOF'
# Fail2ban action for UFW integration

[Definition]
actionstart = 
actionstop = 
actioncheck = 
actionban = ufw insert 1 deny from <ip> to any
actionunban = ufw delete deny from <ip> to any

[Init]
EOF

    # Update jail configuration to use UFW action
    if grep -q "banaction = iptables-multiport" /etc/fail2ban/jail.local; then
        sed -i 's/banaction = iptables-multiport/banaction = ufw/' /etc/fail2ban/jail.local
        log "Updated banaction to use UFW"
    fi
    
    log "UFW integration configured"
}

# Create application logging configuration
configure_application_logging() {
    log "Creating application logging configuration for Docker containers..."
    
    # Create Docker logging configuration
    cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3",
        "labels": "service_name"
    },
    "live-restore": true
}
EOF

    # Create rsyslog configuration for application logs
    cat > /etc/rsyslog.d/50-seneca-bookstore.conf << 'EOF'
# Seneca Book Store application logging configuration

# Create separate log files for each service
if $programname startswith 'seneca-user-service' then /var/log/seneca-bookstore/user-service.log
if $programname startswith 'seneca-catalog-service' then /var/log/seneca-bookstore/catalog-service.log
if $programname startswith 'seneca-order-service' then /var/log/seneca-bookstore/order-service.log
if $programname startswith 'seneca-frontend-service' then /var/log/seneca-bookstore/frontend-service.log

# Authentication related logs
if $msg contains 'authentication' or $msg contains 'login' or $msg contains 'auth' then /var/log/seneca-bookstore/auth.log

# Stop processing these messages further
if $programname startswith 'seneca-' then stop
EOF

    # Restart rsyslog to apply changes
    systemctl restart rsyslog
    
    log "Application logging configured"
}

# Show final status
show_final_status() {
    log "Fail2ban configuration completed!"
    echo
    echo -e "${BLUE}=== Fail2ban Status ===${NC}"
    fail2ban-client status
    echo
    echo -e "${BLUE}=== Active Jails ===${NC}"
    for jail in $(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$'); do
        echo "- $jail"
        fail2ban-client status "$jail" 2>/dev/null | grep -E "(Currently|Total)" || true
    done
    echo
    echo -e "${BLUE}=== Available Commands ===${NC}"
    echo "  sudo seneca-fail2ban-monitor status    - Show detailed status"
    echo "  sudo seneca-fail2ban-monitor banned    - Show banned IPs"
    echo "  sudo seneca-fail2ban-monitor recent    - Show recent activity"
    echo "  sudo seneca-fail2ban-monitor unban IP  - Unban specific IP"
    echo "  sudo seneca-fail2ban-monitor logs      - Show recent logs"
    echo
    echo -e "${YELLOW}=== Important Notes ===${NC}"
    echo "1. SSH protection: Max 3 attempts, 2-hour ban"
    echo "2. Web protection: Rate limiting and bot detection"
    echo "3. Custom app protection: Authentication and API abuse"
    echo "4. UFW integration: Banned IPs added to firewall"
    echo "5. Log monitoring: /var/log/fail2ban.log"
    echo "6. Application logs: /var/log/seneca-bookstore/"
}

# Main execution
main() {
    log "Starting Fail2ban configuration for Seneca Book Store..."
    
    check_root
    install_fail2ban
    backup_fail2ban_config
    configure_fail2ban_main
    configure_custom_filters
    configure_custom_actions
    create_log_directories
    configure_log_rotation
    create_monitoring_script
    configure_ufw_integration
    configure_application_logging
    configure_fail2ban_service
    show_final_status
    
    log "Fail2ban configuration completed successfully!"
}

# Run main function
main "$@"
