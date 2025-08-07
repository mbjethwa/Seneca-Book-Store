#!/bin/bash

# ====================
# Ubuntu System Hardening Script
# Seneca Book Store - Comprehensive Security Hardening
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

# Backup system configuration files
backup_system_config() {
    log "Creating system configuration backup..."
    
    local backup_dir="/etc/security-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup critical configuration files
    cp /etc/sysctl.conf "$backup_dir/" 2>/dev/null || true
    cp /etc/ssh/sshd_config "$backup_dir/" 2>/dev/null || true
    cp /etc/security/limits.conf "$backup_dir/" 2>/dev/null || true
    cp /etc/login.defs "$backup_dir/" 2>/dev/null || true
    cp /etc/pam.d/common-password "$backup_dir/" 2>/dev/null || true
    cp /etc/sudoers "$backup_dir/" 2>/dev/null || true
    cp -r /etc/audit "$backup_dir/" 2>/dev/null || true
    
    log "System configuration backed up to $backup_dir"
}

# Update system and install security packages
update_system() {
    log "Updating system and installing security packages..."
    
    # Update package lists
    apt-get update
    
    # Upgrade system packages
    apt-get upgrade -y
    
    # Install essential security packages
    apt-get install -y \
        unattended-upgrades \
        apt-listchanges \
        needrestart \
        debsums \
        aide \
        auditd \
        audispd-plugins \
        rkhunter \
        chkrootkit \
        logrotate \
        rsyslog \
        apparmor \
        apparmor-utils \
        libpam-tmpdir \
        libpam-pwquality \
        acct \
        psacct \
        sysstat \
        iotop \
        htop \
        fail2ban \
        ufw \
        git \
        curl \
        wget \
        vim \
        nano
    
    # Remove unnecessary packages
    apt-get autoremove -y
    apt-get autoclean
    
    log "System updated and security packages installed"
}

# Disable unnecessary services
disable_unnecessary_services() {
    log "Disabling unnecessary services..."
    
    # List of services to disable (adjust based on your needs)
    local services_to_disable=(
        "bluetooth"
        "cups"
        "cups-browsed"
        "avahi-daemon"
        "whoopsie"
        "apport"
        "ModemManager"
        "snapd.seeded"
        "snapd.socket"
        "snapd.service"
        "lxd"
        "lxd.socket"
    )
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            systemctl disable "$service" &>/dev/null || true
            systemctl stop "$service" &>/dev/null || true
            log "Disabled service: $service"
        fi
    done
    
    # Mask some services to prevent accidental enabling
    local services_to_mask=(
        "ctrl-alt-del.target"
        "shutdown.target"
        "reboot.target"
    )
    
    for service in "${services_to_mask[@]}"; do
        systemctl mask "$service" &>/dev/null || true
        log "Masked service: $service"
    done
    
    log "Unnecessary services disabled"
}

# Configure secure kernel parameters
configure_kernel_parameters() {
    log "Configuring secure kernel parameters..."
    
    # Backup original sysctl.conf
    cp /etc/sysctl.conf /etc/sysctl.conf.backup
    
    # Create comprehensive sysctl configuration
    cat >> /etc/sysctl.conf << 'EOF'

# ====================
# Seneca Book Store Security Hardening
# Kernel Parameters Configuration
# ====================

# Network Security
# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# IP forwarding (disable if not needed as router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# IPv6 router advertisements
net.ipv6.conf.default.router_solicitations = 0
net.ipv6.conf.default.accept_ra_rtr_pref = 0
net.ipv6.conf.default.accept_ra_pinfo = 0
net.ipv6.conf.default.accept_ra_defrtr = 0
net.ipv6.conf.default.autoconf = 0
net.ipv6.conf.default.dad_transmits = 0
net.ipv6.conf.default.max_addresses = 1

# Memory Protection
# Randomize virtual address space
kernel.randomize_va_space = 2

# Restrict core dumps
fs.suid_dumpable = 0

# Hide kernel pointers
kernel.kptr_restrict = 1

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict access to kernel logs
kernel.printk = 3 3 3 3

# Process restrictions
# Restrict ptrace to root
kernel.yama.ptrace_scope = 1

# Performance tuning for security
# File descriptor limits
fs.file-max = 65535

# Network buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# TCP buffer sizes
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Connection tracking
net.netfilter.nf_conntrack_max = 65536

# Shared memory
# Restrict shared memory
kernel.shm_rmid_forced = 1

# Virtual memory settings
vm.mmap_min_addr = 65536
vm.swappiness = 10

# Magic SysRq key (disable for security)
kernel.sysrq = 0

# BPF restrictions
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# User namespace restrictions
user.max_user_namespaces = 0

# Restrict loading TTY line disciplines
dev.tty.ldisc_autoload = 0
EOF

    # Apply the new kernel parameters
    sysctl -p
    
    log "Secure kernel parameters configured"
}

# Configure SSH security
configure_ssh_security() {
    log "Configuring SSH security..."
    
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Create secure SSH configuration
    cat > /etc/ssh/sshd_config << 'EOF'
# Seneca Book Store SSH Security Configuration

# Basic settings
Port 22
Protocol 2
AddressFamily inet

# Authentication
LoginGraceTime 60
PermitRootLogin no
MaxAuthTries 3
MaxSessions 2
MaxStartups 10:30:60

# Key-based authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Password authentication (consider disabling after key setup)
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Kerberos and GSSAPI
KerberosAuthentication no
GSSAPIAuthentication no

# Host-based authentication
HostbasedAuthentication no
IgnoreUserKnownHosts yes
IgnoreRhosts yes

# Forwarding and tunneling
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
X11UseLocalhost yes
PermitTunnel no
GatewayPorts no

# Banner and logging
Banner /etc/ssh/banner
LogLevel VERBOSE
SyslogFacility AUTH

# Client settings
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive no
Compression no

# Environment
AcceptEnv LANG LC_*
PermitUserEnvironment no
PrintMotd no
PrintLastLog yes

# Subsystem
Subsystem sftp internal-sftp

# Ciphers and algorithms (strong crypto only)
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# User restrictions (adjust as needed)
AllowUsers mj
DenyUsers root
EOF

    # Create SSH banner
    cat > /etc/ssh/banner << 'EOF'
*********************************************************************
*                                                                   *
*   AUTHORIZED ACCESS ONLY - Seneca Book Store System              *
*                                                                   *
*   This system is for authorized users only. All activities       *
*   are monitored and logged. Unauthorized access is prohibited    *
*   and will be prosecuted to the full extent of the law.          *
*                                                                   *
*   By proceeding, you acknowledge that you have legitimate        *
*   authorized access to this system.                              *
*                                                                   *
*********************************************************************
EOF

    # Test SSH configuration
    if sshd -t; then
        systemctl restart ssh
        log "SSH security configuration applied"
    else
        error "SSH configuration test failed"
    fi
}

# Set proper file permissions and ownership
configure_file_permissions() {
    log "Setting proper file permissions and ownership..."
    
    # System directories
    chmod 755 /etc
    chmod 644 /etc/passwd
    chmod 640 /etc/shadow
    chown root:shadow /etc/shadow
    chmod 644 /etc/group
    chmod 640 /etc/gshadow
    chown root:shadow /etc/gshadow
    chmod 600 /etc/sudoers
    chmod 644 /etc/sudoers.d/*
    
    # SSH configurations
    chmod 644 /etc/ssh/ssh_config
    chmod 600 /etc/ssh/sshd_config
    chmod 644 /etc/ssh/ssh_host_*_key.pub
    chmod 600 /etc/ssh/ssh_host_*_key
    
    # Log directories
    chmod 755 /var/log
    chmod 640 /var/log/auth.log
    chmod 640 /var/log/syslog
    chmod 640 /var/log/kern.log
    
    # Home directory permissions
    for home_dir in /home/*; do
        if [[ -d "$home_dir" ]]; then
            chmod 750 "$home_dir"
            if [[ -d "$home_dir/.ssh" ]]; then
                chmod 700 "$home_dir/.ssh"
                chmod 600 "$home_dir/.ssh/authorized_keys" 2>/dev/null || true
                chmod 644 "$home_dir/.ssh/*.pub" 2>/dev/null || true
                chmod 600 "$home_dir/.ssh/id_*" 2>/dev/null || true
            fi
        fi
    done
    
    # Temporary directories
    chmod 1777 /tmp
    chmod 1777 /var/tmp
    
    # Remove world-writable files (security risk)
    find / -xdev -type f -perm -0002 -exec chmod o-w {} \; 2>/dev/null || true
    
    # Set umask for secure default permissions
    echo "umask 027" >> /etc/bash.bashrc
    echo "umask 027" >> /etc/profile
    
    log "File permissions and ownership configured"
}

# Configure password policy
configure_password_policy() {
    log "Configuring password policy..."
    
    # Configure PAM password quality
    cat > /etc/security/pwquality.conf << 'EOF'
# Seneca Book Store Password Quality Configuration

# Password length
minlen = 12
minclass = 3

# Character requirements
dcredit = -1    # At least 1 digit
ucredit = -1    # At least 1 uppercase
lcredit = -1    # At least 1 lowercase
ocredit = -1    # At least 1 special character

# Restrictions
maxrepeat = 2   # Max consecutive identical characters
maxclasschars = 0   # Max consecutive characters from same class
reject_username     # Reject passwords containing username
gecoscheck = 1      # Check against GECOS field
enforcing = 1       # Enforce policy

# Dictionary check
dictcheck = 1
dictpath = /usr/share/dict/words
EOF

    # Configure login definitions
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t1/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE\t14/' /etc/login.defs
    sed -i 's/^UMASK.*/UMASK\t\t027/' /etc/login.defs
    
    # Configure account lockout
    cat >> /etc/pam.d/common-auth << 'EOF'

# Account lockout policy
auth required pam_tally2.so deny=5 onerr=fail unlock_time=1800
EOF

    log "Password policy configured"
}

# Enable automatic security updates
configure_automatic_updates() {
    log "Configuring automatic security updates..."
    
    # Configure unattended upgrades
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
// Seneca Book Store Automatic Security Updates Configuration

Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id} ESMApps:${distro_codename}-apps-security";
    "${distro_id} ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
    // Add packages to exclude from automatic updates
    // "vim";
    // "libc6-dev";
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Logging
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";

// Email notifications (configure as needed)
// Unattended-Upgrade::Mail "admin@senecabooks.com";
// Unattended-Upgrade::MailOnlyOnError "true";
EOF

    # Enable automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Enable the service
    systemctl enable unattended-upgrades
    systemctl start unattended-upgrades
    
    log "Automatic security updates configured"
}

# Configure system auditing
configure_system_auditing() {
    log "Configuring system auditing..."
    
    # Configure auditd
    cat > /etc/audit/rules.d/audit.rules << 'EOF'
# Seneca Book Store System Audit Rules

# Remove any existing rules
-D

# Buffer size
-b 8192

# Failure mode (0=silent 1=printk 2=panic)
-f 1

# Monitor authentication events
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Monitor login/logout events
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock -p wa -k logins

# Monitor network configuration
-w /etc/network/ -p wa -k network_config
-w /etc/hosts -p wa -k network_config
-w /etc/hostname -p wa -k network_config
-w /etc/issue -p wa -k network_config
-w /etc/issue.net -p wa -k network_config

# Monitor system configuration
-w /etc/localtime -p wa -k time_config
-w /etc/timezone -p wa -k time_config
-w /etc/ntp.conf -p wa -k time_config
-w /etc/chrony.conf -p wa -k time_config

# Monitor SSH configuration
-w /etc/ssh/sshd_config -p wa -k ssh_config

# Monitor sudoers
-w /etc/sudoers -p wa -k privilege_escalation
-w /etc/sudoers.d/ -p wa -k privilege_escalation

# Monitor cron
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /var/spool/cron/crontabs/ -p wa -k cron

# Monitor kernel module loading
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# Monitor file access
-a always,exit -F arch=b64 -S openat -S open -F exit=-EACCES -k access
-a always,exit -F arch=b64 -S openat -S open -F exit=-EPERM -k access

# Monitor process execution
-a always,exit -F arch=b64 -S execve -k execution

# Monitor privilege escalation
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k privilege_escalation

# Monitor file/directory creation and deletion
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -k file_creation
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_deletion

# Lock configuration
-e 2
EOF

    # Enable and start auditd
    systemctl enable auditd
    systemctl restart auditd
    
    log "System auditing configured"
}

# Configure log rotation and monitoring
configure_logging() {
    log "Configuring logging and monitoring..."
    
    # Configure rsyslog for security logging
    cat > /etc/rsyslog.d/50-security.conf << 'EOF'
# Seneca Book Store Security Logging Configuration

# Security-related logs
auth,authpriv.*                 /var/log/auth.log
kern.*                          /var/log/kern.log
mail.*                          /var/log/mail.log
user.*                          /var/log/user.log
cron.*                          /var/log/cron.log

# Emergency messages to all users
*.emerg                         :omusrmsg:*

# Remote logging (configure as needed)
# *.* @@logserver.example.com:514

# Log file permissions
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
EOF

    # Configure log rotation for security logs
    cat > /etc/logrotate.d/security << 'EOF'
/var/log/auth.log
/var/log/kern.log
/var/log/mail.log
/var/log/user.log
/var/log/cron.log
{
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF

    # Configure audit log rotation
    cat > /etc/logrotate.d/audit << 'EOF'
/var/log/audit/audit.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 600 root root
    postrotate
        /sbin/service auditd restart > /dev/null 2>&1 || true
    endscript
}
EOF

    # Restart logging services
    systemctl restart rsyslog
    
    log "Logging and monitoring configured"
}

# Configure system limits
configure_system_limits() {
    log "Configuring system limits..."
    
    cat > /etc/security/limits.conf << 'EOF'
# Seneca Book Store System Limits Configuration

# Default limits for all users
* soft nofile 65535
* hard nofile 65535
* soft nproc 4096
* hard nproc 4096

# Limits for root
root soft nofile 65535
root hard nofile 65535

# Memory limits (prevent fork bombs)
* hard core 0
* soft core 0

# CPU time limits
* hard cpu 60
* soft cpu 30

# Maximum locked memory
* hard memlock 64
* soft memlock 64

# Maximum file size (100MB)
* hard fsize 102400
* soft fsize 102400
EOF

    log "System limits configured"
}

# Configure AppArmor
configure_apparmor() {
    log "Configuring AppArmor..."
    
    # Enable AppArmor
    systemctl enable apparmor
    systemctl start apparmor
    
    # Set all profiles to enforce mode
    aa-enforce /etc/apparmor.d/*
    
    # Check AppArmor status
    if aa-status | grep -q "profiles are in enforce mode"; then
        log "AppArmor configured and enforcing"
    else
        warn "AppArmor may not be fully configured"
    fi
}

# Install and configure intrusion detection
configure_intrusion_detection() {
    log "Configuring intrusion detection..."
    
    # Configure AIDE (Advanced Intrusion Detection Environment)
    if command -v aide &>/dev/null; then
        # Initialize AIDE database
        aide --init
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        
        # Create daily AIDE check
        cat > /etc/cron.daily/aide << 'EOF'
#!/bin/bash
# Daily AIDE integrity check

aide --check 2>&1 | mail -s "$(hostname) - AIDE Integrity Check" admin@senecabooks.com
EOF
        chmod +x /etc/cron.daily/aide
    fi
    
    # Configure rkhunter
    if command -v rkhunter &>/dev/null; then
        # Update rkhunter database
        rkhunter --update
        rkhunter --propupd
        
        # Configure rkhunter
        sed -i 's/^#MAIL-ON-WARNING=.*/MAIL-ON-WARNING=admin@senecabooks.com/' /etc/rkhunter.conf
        sed -i 's/^#CRON_DAILY_RUN=.*/CRON_DAILY_RUN="true"/' /etc/rkhunter.conf
        sed -i 's/^#CRON_DB_UPDATE=.*/CRON_DB_UPDATE="true"/' /etc/rkhunter.conf
    fi
    
    log "Intrusion detection configured"
}

# Create system monitoring script
create_monitoring_script() {
    log "Creating system monitoring script..."
    
    cat > /usr/local/bin/seneca-security-monitor << 'EOF'
#!/bin/bash

# Seneca Book Store Security Monitoring Script

show_security_status() {
    echo "=== Security Status Report ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime)"
    echo
    
    echo "=== Firewall Status ==="
    ufw status verbose
    echo
    
    echo "=== Fail2ban Status ==="
    fail2ban-client status
    echo
    
    echo "=== SSH Status ==="
    systemctl status ssh --no-pager
    echo
    
    echo "=== Audit Status ==="
    systemctl status auditd --no-pager
    echo
    
    echo "=== AppArmor Status ==="
    aa-status | head -10
    echo
    
    echo "=== System Updates ==="
    apt list --upgradable 2>/dev/null | wc -l
    echo "Available updates: $(apt list --upgradable 2>/dev/null | grep -v "WARNING" | wc -l)"
    echo
    
    echo "=== Disk Usage ==="
    df -h | grep -E '^/dev'
    echo
    
    echo "=== Memory Usage ==="
    free -h
    echo
    
    echo "=== Load Average ==="
    cat /proc/loadavg
    echo
    
    echo "=== Failed Login Attempts ==="
    grep "Failed password" /var/log/auth.log | tail -5
    echo
    
    echo "=== Successful Logins ==="
    grep "Accepted password\|Accepted publickey" /var/log/auth.log | tail -5
    echo
}

check_security_issues() {
    echo "=== Security Issues Check ==="
    
    # Check for world-writable files
    echo "World-writable files:"
    find / -xdev -type f -perm -0002 2>/dev/null | head -10
    echo
    
    # Check for SUID files
    echo "SUID files:"
    find / -xdev -type f -perm -4000 2>/dev/null | head -10
    echo
    
    # Check for files with no owner
    echo "Files with no owner:"
    find / -xdev -nouser -o -nogroup 2>/dev/null | head -10
    echo
    
    # Check for large files
    echo "Large files (>100MB):"
    find / -xdev -type f -size +100M 2>/dev/null | head -10
    echo
    
    # Check listening ports
    echo "Listening ports:"
    ss -tulpn | grep LISTEN
    echo
}

run_security_audit() {
    echo "=== Security Audit ==="
    
    # Run rkhunter check
    if command -v rkhunter &>/dev/null; then
        echo "Running rkhunter scan..."
        rkhunter --check --sk --report-warnings-only
    fi
    
    # Run chkrootkit
    if command -v chkrootkit &>/dev/null; then
        echo "Running chkrootkit scan..."
        chkrootkit | grep -v "nothing found"
    fi
    
    # Check AIDE if available
    if command -v aide &>/dev/null; then
        echo "Running AIDE check..."
        aide --check
    fi
}

update_security() {
    echo "=== Security Updates ==="
    
    # Update package lists
    apt-get update
    
    # Show available security updates
    apt list --upgradable 2>/dev/null | grep -i security
    
    # Apply security updates (uncomment if desired)
    # apt-get upgrade -y
    
    # Update rkhunter database
    if command -v rkhunter &>/dev/null; then
        rkhunter --update --quiet
    fi
}

case "${1:-status}" in
    status|s)
        show_security_status
        ;;
    check|c)
        check_security_issues
        ;;
    audit|a)
        run_security_audit
        ;;
    update|u)
        update_security
        ;;
    all)
        show_security_status
        echo
        check_security_issues
        echo
        run_security_audit
        ;;
    *)
        echo "Seneca Book Store Security Monitor"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  status, s    Show security status"
        echo "  check, c     Check for security issues"
        echo "  audit, a     Run security audit tools"
        echo "  update, u    Check for security updates"
        echo "  all          Run all checks"
        echo
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 check"
        echo "  $0 all"
        ;;
esac
EOF

    chmod +x /usr/local/bin/seneca-security-monitor
    
    # Create daily security check cron job
    cat > /etc/cron.daily/security-check << 'EOF'
#!/bin/bash
# Daily security status check

/usr/local/bin/seneca-security-monitor status | mail -s "$(hostname) - Daily Security Report" admin@senecabooks.com 2>/dev/null || \
/usr/local/bin/seneca-security-monitor status > /var/log/daily-security-check.log
EOF

    chmod +x /etc/cron.daily/security-check
    
    log "System monitoring script created"
}

# Show final security status
show_final_status() {
    log "System hardening completed!"
    echo
    echo -e "${BLUE}=== Security Hardening Summary ===${NC}"
    echo "✅ System updated and security packages installed"
    echo "✅ Unnecessary services disabled"
    echo "✅ Secure kernel parameters configured"
    echo "✅ SSH security hardened"
    echo "✅ File permissions and ownership set"
    echo "✅ Password policy configured"
    echo "✅ Automatic security updates enabled"
    echo "✅ System auditing configured"
    echo "✅ Logging and monitoring configured"
    echo "✅ System limits configured"
    echo "✅ AppArmor enabled"
    echo "✅ Intrusion detection configured"
    echo "✅ Security monitoring script created"
    echo
    echo -e "${BLUE}=== Available Commands ===${NC}"
    echo "  sudo seneca-security-monitor status    - Show security status"
    echo "  sudo seneca-security-monitor check     - Check for security issues"
    echo "  sudo seneca-security-monitor audit     - Run security audit"
    echo "  sudo seneca-security-monitor update    - Check security updates"
    echo
    echo -e "${YELLOW}=== Important Notes ===${NC}"
    echo "1. Reboot recommended to apply all kernel parameters"
    echo "2. Review SSH configuration before disconnecting"
    echo "3. Configure email notifications for alerts"
    echo "4. Regular security monitoring is now automated"
    echo "5. Check logs in /var/log/ for security events"
    echo
    echo -e "${YELLOW}=== Next Steps ===${NC}"
    echo "1. Test SSH access from another terminal"
    echo "2. Configure email for security notifications"
    echo "3. Review and customize security policies as needed"
    echo "4. Schedule regular security audits"
    echo "5. Consider additional hardening based on specific needs"
}

# Main execution
main() {
    log "Starting Ubuntu system hardening for Seneca Book Store..."
    
    check_root
    backup_system_config
    update_system
    disable_unnecessary_services
    configure_kernel_parameters
    configure_ssh_security
    configure_file_permissions
    configure_password_policy
    configure_automatic_updates
    configure_system_auditing
    configure_logging
    configure_system_limits
    configure_apparmor
    configure_intrusion_detection
    create_monitoring_script
    show_final_status
    
    log "Ubuntu system hardening completed successfully!"
}

# Run main function
main "$@"
