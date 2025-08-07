#!/bin/bash

# ====================
# Master Security Setup Script
# Seneca Book Store - Complete Ubuntu Security Hardening
# ====================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

header() {
    echo
    echo -e "${PURPLE}===================================================${NC}"
    echo -e "${PURPLE} $1 ${NC}"
    echo -e "${PURPLE}===================================================${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Check if scripts exist
check_scripts() {
    local scripts=(
        "ufw-docker-config.sh"
        "fail2ban-config.sh"
        "system-hardening.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            error "Required script not found: $script"
        fi
        
        if [[ ! -x "$SCRIPT_DIR/$script" ]]; then
            chmod +x "$SCRIPT_DIR/$script"
            log "Made script executable: $script"
        fi
    done
}

# Show security overview
show_overview() {
    header "SENECA BOOK STORE SECURITY SETUP"
    
    echo -e "${CYAN}This comprehensive security setup will configure:${NC}"
    echo
    echo "📱 1. UFW Firewall Configuration"
    echo "   • Docker/Kubernetes compatible rules"
    echo "   • Service-specific port access"
    echo "   • Rate limiting and logging"
    echo
    echo "🛡️ 2. Fail2ban Intrusion Prevention"
    echo "   • SSH brute force protection"
    echo "   • Web service protection"
    echo "   • Custom application monitoring"
    echo
    echo "🔒 3. System Hardening"
    echo "   • Secure kernel parameters"
    echo "   • SSH security configuration"
    echo "   • File permissions and ownership"
    echo "   • Automatic security updates"
    echo "   • System auditing and monitoring"
    echo
    echo -e "${YELLOW}⚠️ WARNING: This will make significant changes to your system security configuration.${NC}"
    echo -e "${YELLOW}   Please ensure you have:"
    echo "   • Console/physical access to the system"
    echo "   • Backup of important configurations"
    echo "   • Alternative SSH access method${NC}"
    echo
}

# Prompt for confirmation
confirm_setup() {
    echo -e "${CYAN}Do you want to proceed with the complete security setup? [y/N]:${NC} "
    read -r response
    
    case "$response" in
        [yY][eE][sS]|[yY])
            log "Proceeding with security setup..."
            ;;
        *)
            log "Security setup cancelled by user"
            exit 0
            ;;
    esac
}

# Run UFW configuration
run_ufw_config() {
    header "CONFIGURING UFW FIREWALL"
    
    log "Running UFW Docker configuration..."
    
    if "$SCRIPT_DIR/ufw-docker-config.sh"; then
        log "✅ UFW firewall configuration completed successfully"
    else
        error "❌ UFW configuration failed"
    fi
    
    sleep 2
}

# Run Fail2ban configuration
run_fail2ban_config() {
    header "CONFIGURING FAIL2BAN INTRUSION PREVENTION"
    
    log "Running Fail2ban configuration..."
    
    if "$SCRIPT_DIR/fail2ban-config.sh"; then
        log "✅ Fail2ban configuration completed successfully"
    else
        error "❌ Fail2ban configuration failed"
    fi
    
    sleep 2
}

# Run system hardening
run_system_hardening() {
    header "PERFORMING SYSTEM HARDENING"
    
    log "Running system hardening script..."
    
    if "$SCRIPT_DIR/system-hardening.sh"; then
        log "✅ System hardening completed successfully"
    else
        error "❌ System hardening failed"
    fi
    
    sleep 2
}

# Create master monitoring script
create_master_monitor() {
    header "CREATING MASTER MONITORING SYSTEM"
    
    log "Creating comprehensive monitoring script..."
    
    cat > /usr/local/bin/seneca-security-dashboard << 'EOF'
#!/bin/bash

# Seneca Book Store Security Dashboard
# Master monitoring script for all security components

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

header() {
    echo
    echo -e "${PURPLE}===================================================${NC}"
    echo -e "${PURPLE} $1 ${NC}"
    echo -e "${PURPLE}===================================================${NC}"
    echo
}

show_dashboard() {
    clear
    header "SENECA BOOK STORE SECURITY DASHBOARD"
    
    echo -e "${CYAN}System: $(hostname) | Date: $(date) | Uptime: $(uptime -p)${NC}"
    echo
    
    # UFW Status
    echo -e "${BLUE}🔥 FIREWALL STATUS${NC}"
    if systemctl is-active --quiet ufw; then
        echo -e "   Status: ${GREEN}Active${NC}"
        ufw_status=$(ufw status | grep "Status:" | awk '{print $2}')
        echo -e "   UFW: ${GREEN}$ufw_status${NC}"
        
        # Count rules
        rule_count=$(ufw status numbered | grep -c "^\[" || echo "0")
        echo -e "   Rules: ${GREEN}$rule_count active${NC}"
    else
        echo -e "   Status: ${RED}Inactive${NC}"
    fi
    echo
    
    # Fail2ban Status
    echo -e "${BLUE}🛡️ INTRUSION PREVENTION${NC}"
    if systemctl is-active --quiet fail2ban; then
        echo -e "   Status: ${GREEN}Active${NC}"
        
        # Count jails
        jail_count=$(fail2ban-client status | grep "Number of jail:" | awk '{print $4}')
        echo -e "   Jails: ${GREEN}$jail_count active${NC}"
        
        # Count banned IPs
        banned_count=0
        for jail in $(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | tr -d ' ' | grep -v '^$'); do
            banned=$(fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned:" | awk '{print $3}')
            banned_count=$((banned_count + banned))
        done
        echo -e "   Banned IPs: ${YELLOW}$banned_count${NC}"
    else
        echo -e "   Status: ${RED}Inactive${NC}"
    fi
    echo
    
    # SSH Status
    echo -e "${BLUE}🔐 SSH SECURITY${NC}"
    if systemctl is-active --quiet ssh; then
        echo -e "   Status: ${GREEN}Active${NC}"
        
        # Check SSH port
        ssh_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
        echo -e "   Port: ${GREEN}$ssh_port${NC}"
        
        # Check root login
        root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}' || echo "unknown")
        if [[ "$root_login" == "no" ]]; then
            echo -e "   Root Login: ${GREEN}Disabled${NC}"
        else
            echo -e "   Root Login: ${YELLOW}$root_login${NC}"
        fi
    else
        echo -e "   Status: ${RED}Inactive${NC}"
    fi
    echo
    
    # System Updates
    echo -e "${BLUE}📦 SYSTEM UPDATES${NC}"
    if command -v unattended-upgrades &>/dev/null; then
        if systemctl is-active --quiet unattended-upgrades; then
            echo -e "   Auto Updates: ${GREEN}Enabled${NC}"
        else
            echo -e "   Auto Updates: ${YELLOW}Disabled${NC}"
        fi
        
        # Check for available updates
        update_count=$(apt list --upgradable 2>/dev/null | grep -v "WARNING" | wc -l)
        if [[ $update_count -gt 1 ]]; then
            echo -e "   Available: ${YELLOW}$((update_count - 1)) updates${NC}"
        else
            echo -e "   Available: ${GREEN}System up to date${NC}"
        fi
    fi
    echo
    
    # Audit Status
    echo -e "${BLUE}📋 SYSTEM AUDITING${NC}"
    if systemctl is-active --quiet auditd; then
        echo -e "   Status: ${GREEN}Active${NC}"
        
        # Check audit log size
        if [[ -f /var/log/audit/audit.log ]]; then
            audit_size=$(du -h /var/log/audit/audit.log | awk '{print $1}')
            echo -e "   Log Size: ${GREEN}$audit_size${NC}"
        fi
    else
        echo -e "   Status: ${RED}Inactive${NC}"
    fi
    echo
    
    # Resource Usage
    echo -e "${BLUE}💻 SYSTEM RESOURCES${NC}"
    
    # CPU Load
    load_avg=$(cat /proc/loadavg | awk '{print $1}')
    echo -e "   Load Average: ${GREEN}$load_avg${NC}"
    
    # Memory Usage
    mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        echo -e "   Memory Usage: ${RED}${mem_usage}%${NC}"
    elif (( $(echo "$mem_usage > 60" | bc -l) )); then
        echo -e "   Memory Usage: ${YELLOW}${mem_usage}%${NC}"
    else
        echo -e "   Memory Usage: ${GREEN}${mem_usage}%${NC}"
    fi
    
    # Disk Usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 80 ]]; then
        echo -e "   Disk Usage: ${RED}${disk_usage}%${NC}"
    elif [[ $disk_usage -gt 60 ]]; then
        echo -e "   Disk Usage: ${YELLOW}${disk_usage}%${NC}"
    else
        echo -e "   Disk Usage: ${GREEN}${disk_usage}%${NC}"
    fi
    echo
    
    # Recent Security Events
    echo -e "${BLUE}🚨 RECENT SECURITY EVENTS${NC}"
    
    # Failed SSH attempts
    failed_ssh=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -3 | wc -l)
    if [[ $failed_ssh -gt 0 ]]; then
        echo -e "   Failed SSH: ${YELLOW}$failed_ssh recent attempts${NC}"
    else
        echo -e "   Failed SSH: ${GREEN}None${NC}"
    fi
    
    # Recent bans
    recent_bans=$(grep "Ban" /var/log/fail2ban.log 2>/dev/null | tail -3 | wc -l)
    if [[ $recent_bans -gt 0 ]]; then
        echo -e "   Recent Bans: ${YELLOW}$recent_bans${NC}"
    else
        echo -e "   Recent Bans: ${GREEN}None${NC}"
    fi
    echo
}

show_detailed_status() {
    header "DETAILED SECURITY STATUS"
    
    echo -e "${CYAN}Running comprehensive security checks...${NC}"
    echo
    
    # UFW detailed status
    if command -v seneca-firewall &>/dev/null; then
        echo -e "${BLUE}UFW Firewall:${NC}"
        seneca-firewall status | head -20
        echo
    fi
    
    # Fail2ban detailed status
    if command -v seneca-fail2ban-monitor &>/dev/null; then
        echo -e "${BLUE}Fail2ban Status:${NC}"
        seneca-fail2ban-monitor status | head -20
        echo
    fi
    
    # System security status
    if command -v seneca-security-monitor &>/dev/null; then
        echo -e "${BLUE}System Security:${NC}"
        seneca-security-monitor status | head -20
        echo
    fi
}

run_security_check() {
    header "SECURITY HEALTH CHECK"
    
    echo -e "${CYAN}Running security health check...${NC}"
    echo
    
    # Check if all security services are running
    services=("ufw" "fail2ban" "ssh" "auditd" "rsyslog")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "✅ $service: ${GREEN}Running${NC}"
        else
            echo -e "❌ $service: ${RED}Not Running${NC}"
        fi
    done
    
    echo
    
    # Run system security monitor if available
    if command -v seneca-security-monitor &>/dev/null; then
        seneca-security-monitor check
    fi
}

interactive_menu() {
    while true; do
        header "SECURITY MANAGEMENT MENU"
        
        echo "1) 📊 Security Dashboard"
        echo "2) 🔍 Detailed Status"
        echo "3) 🏥 Security Health Check"
        echo "4) 🔥 Manage Firewall"
        echo "5) 🛡️ Manage Fail2ban"
        echo "6) 🔒 System Security"
        echo "7) 📋 View Logs"
        echo "8) 🔄 Refresh View"
        echo "9) ❌ Exit"
        echo
        echo -e "${CYAN}Select an option [1-9]:${NC} "
        read -r choice
        
        case $choice in
            1) show_dashboard ;;
            2) show_detailed_status ;;
            3) run_security_check ;;
            4) 
                if command -v seneca-firewall &>/dev/null; then
                    seneca-firewall status
                else
                    echo "UFW management script not found"
                fi
                ;;
            5)
                if command -v seneca-fail2ban-monitor &>/dev/null; then
                    seneca-fail2ban-monitor status
                else
                    echo "Fail2ban monitoring script not found"
                fi
                ;;
            6)
                if command -v seneca-security-monitor &>/dev/null; then
                    seneca-security-monitor status
                else
                    echo "System security monitor not found"
                fi
                ;;
            7)
                echo "Recent security logs:"
                echo "1) Auth log    2) Fail2ban log    3) UFW log    4) Audit log"
                read -p "Select log [1-4]: " log_choice
                case $log_choice in
                    1) tail -20 /var/log/auth.log ;;
                    2) tail -20 /var/log/fail2ban.log ;;
                    3) tail -20 /var/log/ufw.log ;;
                    4) tail -20 /var/log/audit/audit.log ;;
                esac
                ;;
            8) clear ;;
            9) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

case "${1:-dashboard}" in
    dashboard|d)
        show_dashboard
        ;;
    status|s)
        show_detailed_status
        ;;
    check|c)
        run_security_check
        ;;
    menu|m)
        interactive_menu
        ;;
    *)
        echo "Seneca Book Store Security Dashboard"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  dashboard, d    Show security dashboard (default)"
        echo "  status, s       Show detailed status"
        echo "  check, c        Run security health check"
        echo "  menu, m         Interactive menu"
        echo
        echo "Examples:"
        echo "  $0 dashboard"
        echo "  $0 status"
        echo "  $0 menu"
        ;;
esac
EOF

    chmod +x /usr/local/bin/seneca-security-dashboard
    
    log "✅ Master monitoring system created"
}

# Create maintenance and update script
create_maintenance_script() {
    log "Creating maintenance and update script..."
    
    cat > /usr/local/bin/seneca-security-maintenance << 'EOF'
#!/bin/bash

# Seneca Book Store Security Maintenance Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Update all security components
update_security() {
    log "Updating security components..."
    
    # Update system packages
    apt-get update
    apt-get upgrade -y
    
    # Update fail2ban filters
    if systemctl is-active --quiet fail2ban; then
        systemctl reload fail2ban
    fi
    
    # Update rkhunter database
    if command -v rkhunter &>/dev/null; then
        rkhunter --update --quiet
    fi
    
    # Update AIDE database if needed
    if command -v aide &>/dev/null && [[ -f /var/lib/aide/aide.db ]]; then
        # Check if system files have been updated
        if find /bin /sbin /usr/bin /usr/sbin -newer /var/lib/aide/aide.db | grep -q .; then
            log "Updating AIDE database due to system changes..."
            aide --init
            mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        fi
    fi
    
    log "Security components updated"
}

# Run comprehensive security audit
run_audit() {
    log "Running comprehensive security audit..."
    
    # Check system security
    if command -v seneca-security-monitor &>/dev/null; then
        seneca-security-monitor audit
    fi
    
    # Check fail2ban status
    if command -v seneca-fail2ban-monitor &>/dev/null; then
        seneca-fail2ban-monitor status
    fi
    
    # Check firewall status
    if command -v seneca-firewall &>/dev/null; then
        seneca-firewall status
    fi
    
    log "Security audit completed"
}

# Clean up logs and temporary files
cleanup() {
    log "Cleaning up logs and temporary files..."
    
    # Clean old logs
    find /var/log -name "*.log.*" -mtime +30 -delete 2>/dev/null || true
    find /var/log -name "*.gz" -mtime +30 -delete 2>/dev/null || true
    
    # Clean temporary files
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true
    
    # Clean package cache
    apt-get autoclean
    apt-get autoremove -y
    
    log "Cleanup completed"
}

# Generate security report
generate_report() {
    local report_file="/var/log/security-report-$(date +%Y%m%d).log"
    
    log "Generating security report..."
    
    {
        echo "=== Seneca Book Store Security Report ==="
        echo "Date: $(date)"
        echo "System: $(hostname)"
        echo
        
        if command -v seneca-security-dashboard &>/dev/null; then
            seneca-security-dashboard status
        fi
        
    } > "$report_file"
    
    log "Security report saved to $report_file"
}

case "${1:-update}" in
    update|u)
        update_security
        ;;
    audit|a)
        run_audit
        ;;
    cleanup|c)
        cleanup
        ;;
    report|r)
        generate_report
        ;;
    all)
        update_security
        run_audit
        cleanup
        generate_report
        ;;
    *)
        echo "Seneca Book Store Security Maintenance"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  update, u    Update security components"
        echo "  audit, a     Run security audit"
        echo "  cleanup, c   Clean up logs and temporary files"
        echo "  report, r    Generate security report"
        echo "  all          Run all maintenance tasks"
        ;;
esac
EOF

    chmod +x /usr/local/bin/seneca-security-maintenance
    
    # Create weekly maintenance cron job
    cat > /etc/cron.weekly/security-maintenance << 'EOF'
#!/bin/bash
# Weekly security maintenance

/usr/local/bin/seneca-security-maintenance all
EOF

    chmod +x /etc/cron.weekly/security-maintenance
    
    log "✅ Maintenance and update script created"
}

# Show final security report
show_final_report() {
    header "SECURITY SETUP COMPLETE"
    
    echo -e "${GREEN}🎉 Congratulations! Your Seneca Book Store system is now comprehensively secured.${NC}"
    echo
    echo -e "${CYAN}📊 Security Components Installed:${NC}"
    echo "✅ UFW Firewall - Docker/Kubernetes compatible"
    echo "✅ Fail2ban - Intrusion prevention system"
    echo "✅ System Hardening - Comprehensive security configuration"
    echo "✅ Security Monitoring - Automated monitoring and alerting"
    echo "✅ Maintenance Tools - Automated updates and maintenance"
    echo
    echo -e "${CYAN}🛠️ Available Commands:${NC}"
    echo "  sudo seneca-security-dashboard        - Main security dashboard"
    echo "  sudo seneca-security-monitor          - System security monitoring"
    echo "  sudo seneca-fail2ban-monitor          - Fail2ban management"
    echo "  sudo seneca-firewall                  - UFW firewall management"
    echo "  sudo seneca-security-maintenance      - Maintenance and updates"
    echo
    echo -e "${CYAN}📱 Quick Access:${NC}"
    echo "  Security Dashboard:    sudo seneca-security-dashboard"
    echo "  Interactive Menu:      sudo seneca-security-dashboard menu"
    echo "  Security Status:       sudo seneca-security-dashboard status"
    echo "  Health Check:          sudo seneca-security-dashboard check"
    echo
    echo -e "${YELLOW}⚠️ Important Notes:${NC}"
    echo "• Reboot recommended to apply all kernel security parameters"
    echo "• Test SSH access from another session before disconnecting"
    echo "• Configure email notifications for security alerts"
    echo "• Review security logs regularly"
    echo "• Keep security tools updated"
    echo
    echo -e "${YELLOW}📋 Post-Setup Tasks:${NC}"
    echo "1. Test SSH access: ssh user@$(hostname -I | awk '{print $1}')"
    echo "2. Configure email notifications"
    echo "3. Review and customize security policies"
    echo "4. Set up regular security audits"
    echo "5. Test disaster recovery procedures"
    echo
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo "• UFW Configuration: /home/mj/Seneca Book Store/security/UFW-README.md"
    echo "• Fail2ban Setup: /home/mj/Seneca Book Store/security/FAIL2BAN-README.md"
    echo "• Docker Security: /home/mj/Seneca Book Store/security/docker/README.md"
    echo
    
    # Run initial security dashboard
    echo -e "${CYAN}🔍 Initial Security Status:${NC}"
    echo
    sleep 2
    /usr/local/bin/seneca-security-dashboard dashboard
}

# Main execution
main() {
    check_root
    check_scripts
    show_overview
    confirm_setup
    
    log "Starting comprehensive security setup..."
    
    # Run security configurations
    run_ufw_config
    run_fail2ban_config
    run_system_hardening
    
    # Create monitoring and maintenance tools
    create_master_monitor
    create_maintenance_script
    
    # Show final report
    show_final_report
    
    log "🎉 Complete security setup finished successfully!"
    
    echo
    echo -e "${PURPLE}═══════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}     SENECA BOOK STORE SECURITY SETUP COMPLETE     ${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════${NC}"
}

# Run main function
main "$@"
