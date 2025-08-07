# Fail2ban Security Configuration Guide
# Seneca Book Store - Brute Force Protection

## Overview
This comprehensive Fail2ban implementation provides enterprise-grade protection against brute force attacks on SSH, web services, and custom application authentication for the Seneca Book Store microservices architecture.

## 🔒 Security Features Implemented

### 1. SSH Protection
- **sshd jail**: Protects against SSH brute force attacks
  - Max 3 attempts in 5 minutes
  - 2-hour ban duration
  - Monitors: `/var/log/auth.log`

- **sshd-ddos jail**: Protects against SSH connection flooding
  - Max 2 attempts in 2 minutes
  - 2-hour ban duration
  - Currently disabled (enable when needed)

### 2. Web Service Protection
- **nginx-http-auth**: HTTP authentication failure protection
- **nginx-limit-req**: Rate limiting violation protection
- **nginx-botsearch**: Bot and vulnerability scanner detection
- Currently disabled (will auto-enable when nginx is detected)

### 3. Application Protection
- **seneca-auth-failure**: Custom authentication failure detection
- **seneca-api-abuse**: API abuse and injection attempt protection
- Currently disabled (will auto-enable when application logs are available)

### 4. Container Protection
- **docker-auth**: Docker registry authentication protection
- Currently disabled (will auto-enable when Docker registry is detected)

## 📁 File Structure

```
/etc/fail2ban/
├── jail.local                     # Main configuration
├── filter.d/
│   ├── seneca-auth-failure.conf   # Custom auth failure filter
│   ├── seneca-api-abuse.conf      # Custom API abuse filter
│   ├── docker-auth.conf           # Docker auth filter
│   └── nginx-botsearch.conf       # Enhanced bot detection
├── action.d/
│   ├── ufw.conf                   # UFW integration action
│   └── seneca-notification.conf   # Custom notification action
└── backup-*/                      # Configuration backups

/var/log/seneca-bookstore/
├── auth.log                       # Authentication events
├── user-service.log               # User service logs
├── catalog-service.log            # Catalog service logs
├── order-service.log              # Order service logs
└── frontend-service.log           # Frontend service logs

/usr/local/bin/
├── seneca-fail2ban-monitor        # Monitoring script
└── /security/fail2ban-jail-manager.sh  # Jail management
```

## 🚀 Quick Start

### 1. Check Current Status
```bash
sudo seneca-fail2ban-monitor status
sudo security/fail2ban-jail-manager.sh status
```

### 2. Enable Additional Protection (when services are running)
```bash
# Enable web protection (when nginx is running)
sudo security/fail2ban-jail-manager.sh enable-web

# Enable application protection (when services are logging)
sudo security/fail2ban-jail-manager.sh enable-app

# Enable Docker protection (when registry is running)
sudo security/fail2ban-jail-manager.sh enable-docker

# Enable all protection at once
sudo security/fail2ban-jail-manager.sh enable-all
```

### 3. Monitor Activity
```bash
# Show banned IPs
sudo seneca-fail2ban-monitor banned

# Show recent activity
sudo seneca-fail2ban-monitor recent

# Show logs
sudo seneca-fail2ban-monitor logs 50
```

## 🔧 Detailed Configuration

### Jail Settings
| Jail | Purpose | Max Retry | Ban Time | Find Time | Status |
|------|---------|-----------|----------|-----------|---------|
| sshd | SSH brute force | 3 | 2 hours | 5 minutes | ✅ Active |
| sshd-ddos | SSH connection flood | 2 | 2 hours | 2 minutes | ⏸️ Disabled |
| nginx-http-auth | HTTP auth failures | 3 | 1 hour | 10 minutes | ⏸️ Disabled |
| nginx-limit-req | Rate limit violations | 5 | 30 minutes | 5 minutes | ⏸️ Disabled |
| nginx-botsearch | Bot/scanner detection | 2 | 24 hours | 10 minutes | ⏸️ Disabled |
| seneca-auth-failure | App auth failures | 5 | 2 hours | 10 minutes | ⏸️ Disabled |
| seneca-api-abuse | API abuse attempts | 10 | 1 hour | 5 minutes | ⏸️ Disabled |
| docker-auth | Docker registry auth | 3 | 1 hour | 5 minutes | ⏸️ Disabled |

### Custom Filters

#### Authentication Failure Patterns
The `seneca-auth-failure` filter detects:
- Authentication failed from IP
- Invalid credentials from IP
- Login attempt failed from IP
- Unauthorized access from IP
- Invalid token from IP
- JWT invalid from IP

#### API Abuse Patterns
The `seneca-api-abuse` filter detects:
- Rate limit exceeded from IP
- Too many requests from IP
- API quota exceeded from IP
- SQL injection attempts
- XSS attempts
- Path traversal attempts

### Integration Features

#### UFW Firewall Integration
- Banned IPs are automatically added to UFW deny rules
- Provides layered security with firewall blocking
- Unbanning removes UFW rules automatically

#### Logging and Monitoring
- Centralized logging to `/var/log/fail2ban.log`
- Application-specific logs in `/var/log/seneca-bookstore/`
- Log rotation configured (30 days retention)
- Real-time monitoring with custom scripts

## 📊 Monitoring and Management

### Status Monitoring
```bash
# Comprehensive status check
sudo seneca-fail2ban-monitor status

# Currently banned IPs across all jails
sudo seneca-fail2ban-monitor banned

# Recent ban/unban activity
sudo seneca-fail2ban-monitor recent

# Configuration overview
sudo seneca-fail2ban-monitor config
```

### Manual IP Management
```bash
# Ban an IP manually
sudo seneca-fail2ban-monitor ban 192.168.1.100 sshd

# Unban an IP from specific jail
sudo seneca-fail2ban-monitor unban 192.168.1.100 sshd

# Unban an IP from all jails
sudo seneca-fail2ban-monitor unban 192.168.1.100
```

### Jail Management
```bash
# List all available jails
sudo security/fail2ban-jail-manager.sh list

# Enable specific jail
sudo security/fail2ban-jail-manager.sh enable nginx-http-auth

# Disable specific jail
sudo security/fail2ban-jail-manager.sh disable nginx-http-auth

# Test jail configuration
sudo security/fail2ban-jail-manager.sh test seneca-auth-failure
```

### Filter Testing
```bash
# Test filters against log files
sudo seneca-fail2ban-monitor test

# Test specific filter manually
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# Test custom application filter
sudo fail2ban-regex /var/log/seneca-bookstore/auth.log /etc/fail2ban/filter.d/seneca-auth-failure.conf
```

## 🛡️ Security Best Practices

### 1. Gradual Enablement
- ✅ SSH protection enabled immediately (essential)
- ⏳ Web protection enabled when nginx is running
- ⏳ Application protection enabled when services are logging
- ⏳ Docker protection enabled when registry is active

### 2. Log Monitoring
- ✅ Regular log review and analysis
- ✅ Automated log rotation (30 days)
- ✅ Centralized logging for all services
- ✅ Real-time monitoring with alerts

### 3. IP Whitelist Management
- Configure trusted IP ranges in `ignoreip`
- Regular review of banned IPs
- Emergency unban procedures documented
- Backup access methods established

### 4. Integration Security
- ✅ UFW firewall integration active
- ✅ System logging integration
- ✅ Email notifications configured
- ✅ Monitoring script automation

## 🔍 Troubleshooting

### Common Issues

**Fail2ban Won't Start**
```bash
# Check configuration syntax
sudo fail2ban-server -t

# Check service status
sudo systemctl status fail2ban

# View detailed logs
sudo journalctl -u fail2ban -f
```

**Jail Not Working**
```bash
# Test jail configuration
sudo security/fail2ban-jail-manager.sh test <jail-name>

# Check log file permissions
ls -la /var/log/seneca-bookstore/

# Verify filter patterns
sudo fail2ban-regex <logfile> <filter-file>
```

**False Positives**
```bash
# Add IP to ignore list
sudo nano /etc/fail2ban/jail.local
# Add to ignoreip = 127.0.0.1/8 ::1 YOUR_IP

# Unban legitimate IP
sudo seneca-fail2ban-monitor unban <IP>

# Adjust retry thresholds
sudo nano /etc/fail2ban/jail.local
```

### Log Analysis

**Check Recent Bans**
```bash
sudo grep "Ban" /var/log/fail2ban.log | tail -10
```

**Analyze Attack Patterns**
```bash
sudo grep "Found" /var/log/fail2ban.log | awk '{print $NF}' | sort | uniq -c | sort -nr
```

**Monitor Specific Service**
```bash
sudo tail -f /var/log/seneca-bookstore/auth.log
```

## 📋 Maintenance Schedule

### Daily
- Check banned IP list
- Review recent attack patterns
- Monitor jail status

### Weekly
- Analyze attack trends
- Update filter patterns if needed
- Review whitelist requirements

### Monthly
- Archive old logs
- Update configuration based on patterns
- Test emergency procedures

## 🤝 Integration with Services

### When Starting Nginx
```bash
sudo security/fail2ban-jail-manager.sh enable-web
```

### When Starting Seneca Book Store Services
```bash
# Ensure logging is configured in Docker containers
# Enable application protection
sudo security/fail2ban-jail-manager.sh enable-app
```

### When Starting Docker Registry
```bash
sudo security/fail2ban-jail-manager.sh enable-docker
```

## 📞 Emergency Procedures

### If Locked Out via SSH
1. Use console access (VM console, physical access)
2. Unban your IP: `sudo seneca-fail2ban-monitor unban YOUR_IP`
3. Add IP to whitelist if permanent access needed

### If False Positive Blocking
1. Identify affected service/jail
2. Unban IP immediately
3. Adjust filter or thresholds
4. Test configuration before reloading

### If Service Under Attack
1. Monitor with: `sudo seneca-fail2ban-monitor status`
2. Review attack patterns in logs
3. Consider lowering thresholds temporarily
4. Add additional IP ranges to blocklist if needed

---

**Note**: This configuration provides robust protection while maintaining usability. Jails are disabled by default to prevent issues during initial setup and will be enabled automatically as services become available.
