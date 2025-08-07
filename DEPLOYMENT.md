# 🚀 Deployment Guide - Seneca Book Store

Complete deployment guide for the Seneca Book Store microservices application with unified deployment script.

## 📋 Prerequisites

### Required Tools
- **Docker** & **Docker Compose** (latest version)
- **Kubernetes** - Minikube (local) or managed cluster (production)
- **kubectl** - configured for your cluster
- **Git** - for cloning the repository

### System Requirements
- **Memory**: 8GB+ RAM recommended
- **Disk Space**: 10GB+ available space
- **CPU**: 4+ cores recommended

## � Security Setup

### Environment Configuration
```bash
# Copy example configuration
cp .env.example .env

# The deployment script will auto-generate secure secrets
# Or manually set:
SECRET_KEY=$(openssl rand -base64 32)
echo "SECRET_KEY=$SECRET_KEY" >> .env
```

### Kubernetes Security
- RBAC policies automatically configured
- Network policies with zero-trust model
- TLS/HTTPS enforced for all communications
- Secrets management via Kubernetes Secrets

## 🚀 Quick Deployment

### One-Command Deployment
```bash
# Deploy everything (recommended)
./deploy.sh

# Deploy to specific environment
./deploy.sh --k8s      # Kubernetes only
./deploy.sh --docker   # Docker Compose only
```

### Deployment Options
```bash
# Check deployment status
./deploy.sh status

# View detailed logs
./deploy.sh logs

# Clean deployment (reset everything)
./shutdown.sh clean && ./deploy.sh
```

## 🔧 Environment-Specific Deployment

### Local Development (Docker Compose)
```bash
# Start all services locally
./deploy.sh --docker

# Access application
open http://localhost:3000

# Admin credentials
Email: admin@senecabooks.com
Password: admin123
```

### Production (Kubernetes)
```bash
# Deploy to Kubernetes cluster
./deploy.sh --k8s

# Setup domain (add to /etc/hosts)
echo "$(minikube ip) senecabooks.local" | sudo tee -a /etc/hosts

# Access application
open http://senecabooks.local

# Monitoring
open http://senecabooks.local/prometheus
open http://senecabooks.local/grafana
```

## 📊 Monitoring & Observability

### Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards and visualization
- **Health Checks**: All services expose `/health` endpoints

### Access Monitoring
```bash
# Prometheus (metrics and alerts)
open http://senecabooks.local/prometheus

# Grafana (dashboards)
open http://senecabooks.local/grafana
# Login: admin / admin123
```

### Key Metrics Tracked
- **HTTP Requests**: Rate, duration, error rate
- **Business Metrics**: User registrations, book views, orders
- **System Health**: Service status, resource usage
- **Security Events**: Authentication attempts, failures

## 🧪 Testing & Validation

### Automated Testing
```bash
# Run comprehensive test suite
./test.sh

# Individual test categories
./test.sh unit        # Unit tests only
./test.sh integration # API integration tests
./test.sh load        # Load testing
```

### Manual Validation
```bash
# Check all services are running
kubectl get pods -n seneca-bookstore

# Test API endpoints
curl http://senecabooks.local/api/user/health
curl http://senecabooks.local/api/catalog/health
curl http://senecabooks.local/api/order/health

# View service logs
kubectl logs -f deployment/user-service -n seneca-bookstore
```

## 🔍 Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check pod status
kubectl get pods -n seneca-bookstore

# View detailed events
kubectl describe pod <pod-name> -n seneca-bookstore

# Check resource usage
kubectl top pods -n seneca-bookstore
```

**Domain access issues:**
```bash
# Verify minikube IP
minikube ip

# Check ingress configuration
kubectl get ingress -n seneca-bookstore

# Test with port-forward
kubectl port-forward service/frontend-service 3000:80 -n seneca-bookstore
```

**Database/Storage issues:**
```bash
# Check persistent volumes
kubectl get pv,pvc -n seneca-bookstore

# Reset storage (WARNING: destroys data)
kubectl delete pvc --all -n seneca-bookstore
```

### Reset Environment
```bash
# Complete reset (removes all data)
./shutdown.sh clean

# Fresh deployment
./deploy.sh

# Verify clean state
kubectl get all -n seneca-bookstore
```

### Performance Optimization
```bash
# Scale services (if needed)
kubectl scale deployment user-service --replicas=3 -n seneca-bookstore

# Monitor resource usage
kubectl top nodes
kubectl top pods -n seneca-bookstore

# View resource limits
kubectl describe deployment user-service -n seneca-bookstore
```

## 🔄 Updates & Maintenance

### Updating the Application
```bash
# Pull latest changes
git pull origin main

# Redeploy with updates
./deploy.sh

# Rolling update (zero downtime)
kubectl rollout restart deployment/user-service -n seneca-bookstore
```

### Backup & Recovery
```bash
# Backup persistent data
kubectl get pv -o yaml > backup-volumes.yaml

# Export configuration
kubectl get configmap,secret -n seneca-bookstore -o yaml > backup-config.yaml

# Restore from backup
kubectl apply -f backup-volumes.yaml
kubectl apply -f backup-config.yaml
```

## 📞 Support

### Logs and Debugging
```bash
# View aggregated logs
kubectl logs -l app=user-service -n seneca-bookstore --tail=100

# Follow real-time logs
kubectl logs -f deployment/user-service -n seneca-bookstore

# Check system events
kubectl get events -n seneca-bookstore --sort-by='.lastTimestamp'
```

### Health Checks
All services provide health endpoints:
- **Frontend**: http://senecabooks.local/
- **User Service**: http://senecabooks.local/api/user/health
- **Catalog Service**: http://senecabooks.local/api/catalog/health
- **Order Service**: http://senecabooks.local/api/order/health

---

**🎯 Enterprise Ready** | **🔒 Security Hardened** | **📈 Production Monitoring** | **🚀 One-Command Deploy**

# Generate secure Grafana password
GRAFANA_PASSWORD=$(openssl rand -base64 16)
echo "GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASSWORD" >> .env
```

#### 2. Secure Test Credentials
```bash
# Never use hardcoded passwords - generate secure credentials
python scripts/generate_secure_credentials.py

# This creates test_credentials.json with secure random passwords
# Use these credentials for testing instead of hardcoded values
```

#### 3. Production Security Checklist
- [ ] **SECRET_KEY**: Generate and securely store a cryptographic key
- [ ] **Database**: Use PostgreSQL with encrypted connections in production
- [ ] **TLS Certificates**: Ensure valid certificates for HTTPS
- [ ] **Network Security**: Review and apply network policies
- [ ] **Access Control**: Configure proper RBAC permissions
- [ ] **Monitoring**: Enable security monitoring and alerting
- [ ] **Backups**: Set up encrypted database backups

#### 4. Security Best Practices
```bash
# Kubernetes Secret Management
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY="$SECRET_KEY" \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --namespace=seneca-bookstore

# Verify secrets are properly configured
kubectl get secrets -n seneca-bookstore
```

**⚠️ IMPORTANT**: Never commit `.env` files or credentials to version control!

## 🛠️ Prerequisites

### Required Tools
- **Docker**: Version 20.10+ with Docker Compose V2
- **kubectl**: Version 1.25+ (Kubernetes CLI)
- **Minikube**: Version 1.30+ (Local Kubernetes cluster)
- **Git**: For cloning the repository

### Optional Tools
- **Helm**: Version 3.0+ (Advanced Kubernetes package management)
- **Node.js**: Version 18+ (For local frontend development)
- **Python**: Version 3.11+ (For local backend development)

### System Requirements
- **Memory**: 8GB+ RAM (for Minikube)
- **Storage**: 20GB+ available disk space
- **CPU**: 2+ cores recommended

## ⚡ Quick Start

### One-Command Deployment Options
```bash
# Clone and deploy everything
git clone <repository-url>
cd "Seneca Book Store"
./deploy.sh --k8s deploy

# Access the application
open https://senecabooks.local
```

### Quick Status Check
```bash
# Check deployment status
./deploy.sh status

# View application logs
./deploy.sh logs user-service
```

### Quick Status Check
```bash
# Check deployment status
./deploy.sh status

# View application logs  
./deploy.sh --k8s logs user-service
./deploy.sh --docker logs user-service
```

## 🎯 Unified Deployment Script

The project features a powerful comprehensive deployment script (`deploy.sh`) that supports multiple deployment modes with a single interface.

### Deployment Modes

#### 1. Kubernetes Only (`--k8s`)
```bash
./deploy.sh --k8s deploy
```
- Deploys to Minikube cluster
- Sets up TLS with cert-manager
- Configures Ingress at https://senecabooks.local
- Includes persistent storage and monitoring

#### 2. Docker Compose Only (`--docker`)
```bash
./deploy.sh --docker deploy
```
- Local development deployment
- Services accessible on localhost
- Volume mounts for data persistence
- Easy debugging and testing

#### 3. Both Deployments (`--both`)
```bash
./deploy.sh --both deploy
```
- Deploys both environments
- Useful for testing and validation
- Compare behavior between environments

### Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `deploy` | Full deployment (default) | `./deploy.sh --k8s deploy` |
| `build` | Build Docker images only | `./deploy.sh build` |
| `status` | Show deployment status | `./deploy.sh status` |
| `logs` | View service logs | `./deploy.sh --k8s logs user-service` |
| `cleanup` | Clean up deployments | `./deploy.sh cleanup` |
| `seed` | Seed initial data | `./deploy.sh --docker seed` |
| `help` | Show help message | `./deploy.sh help` |

## ☸️ Kubernetes Deployment (Production)

### Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Ingress     │    │   cert-manager  │    │  Persistent     │
│  (TLS + Routes) │◄──►│  (SSL Certs)    │    │  Storage        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                              │
         ▼                                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Frontend       │    │   Backend       │    │   ConfigMaps    │
│  (React/Nginx)  │◄──►│  Services       │◄──►│   & Secrets     │
│  Port: 80       │    │  Port: 8000     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Full Deployment Process

#### 1. Prerequisites Check
```bash
# The script automatically checks for required tools
./deploy.sh --k8s deploy

# Manual prerequisite check
minikube version
kubectl version --client
docker --version
```

#### 2. Automatic Deployment Steps
The `deploy.sh` script automatically handles:

1. ✅ **Minikube Setup**: Starts with optimal configuration
2. ✅ **Addon Installation**: Enables ingress, registry, dashboard
3. ✅ **cert-manager**: Installs for TLS certificate management
4. ✅ **Image Building**: Builds all Docker images locally
5. ✅ **Registry Setup**: Configures local registry access
6. ✅ **Kubernetes Manifests**: Applies all configurations
7. ✅ **Health Monitoring**: Waits for all services to be ready
8. ✅ **Data Seeding**: Creates admin user and sample books
9. ✅ **Hosts Configuration**: Sets up `senecabooks.local` domain

#### 3. Deployment Commands

```bash
# Full deployment (recommended)
./deploy.sh --k8s deploy

# Build images only
./deploy.sh --k8s build

# Apply Kubernetes configs only
./deploy.sh --k8s apply

# Run health checks
./deploy.sh --k8s test

# Seed initial data
./deploy.sh --k8s seed

# Check deployment status
./deploy.sh --k8s status

# View service logs
./deploy.sh --k8s logs <service-name>

# Scale services
./deploy.sh --k8s scale <service-name> <replicas>
```

#### 4. Accessing the Application

Once deployed, access the application at:
- **Main Application**: https://senecabooks.local
- **User Service API**: https://senecabooks.local/api/user/docs
- **Catalog Service API**: https://senecabooks.local/api/catalog/docs
- **Order Service API**: https://senecabooks.local/api/order/docs

#### 5. Default Credentials
```
Admin User: admin@seneca.ca / admin123
Regular User: user@seneca.ca / user123
```

### Kubernetes Resource Architecture

#### Namespace Organization
```yaml
seneca-bookstore/
├── user-service (Deployment + Service)
├── catalog-service (Deployment + Service)
├── order-service (Deployment + Service)
├── frontend-service (Deployment + Service)
├── bookstore-config (ConfigMap)
├── bookstore-secrets (Secret)
├── bookstore-data-pvc (PersistentVolumeClaim)
└── senecabooks-ingress (Ingress with TLS)
```

#### Storage Configuration
- **Persistent Volume**: 5GB for database storage
- **Mount Path**: `/data` in all backend containers
- **Database Files**:
  - `/data/users.db` (User service)
  - `/data/catalog.db` (Catalog service)
  - `/data/orders.db` (Order service)

#### Security Configuration
- **TLS Certificates**: Self-signed via cert-manager
- **JWT Secrets**: Stored in Kubernetes Secrets
- **Network Policies**: Ingress-controlled access
- **Resource Limits**: CPU/Memory limits on all pods

## 🔐 Security Features

### Comprehensive Security Implementation

The Seneca Book Store implements enterprise-grade security features for production deployment:

#### 1. RBAC (Role-Based Access Control)
```yaml
Service Accounts & Permissions:
- user-service-sa: Access to secrets and ConfigMaps
- catalog-service-sa: Read-only access to resources  
- order-service-sa: Standard service permissions
- frontend-service-sa: Minimal read-only access
```

#### 2. Network Policies
```yaml
Security Rules:
- Default deny-all traffic policy
- Allow internal service-to-service communication only
- Block external access except via Ingress controller
- DNS resolution allowed for all services
```

#### 3. Comprehensive Logging
```bash
# All API calls logged with:
Method: GET | Path: /api/books | User: admin@seneca.ca | Status: 200 | Time: 0.045s
Method: POST | Path: /api/orders | User: user@seneca.ca | Status: 201 | Time: 0.123s
Method: GET | Path: /health | User: anonymous | Status: 200 | Time: 0.012s
```

#### 4. TLS/HTTPS Encryption
- Automatic certificate management with cert-manager
- All traffic encrypted in transit
- Secure communication between services

#### 5. Security Verification
```bash
# Verify RBAC is working
kubectl auth can-i get secrets --as=system:serviceaccount:seneca-bookstore:catalog-service-sa

# Check network policies
kubectl get networkpolicies -n seneca-bookstore

# View security logs
kubectl logs -f deployment/user-service -n seneca-bookstore | grep "Method:"
```

### Shutdown and Cleanup

#### Shutdown Options
```bash
# Soft shutdown (preserve everything, scale down pods)
./shutdown.sh soft

# Remove application (keep Minikube for other projects)
./shutdown.sh app

# Full shutdown (stop Minikube, preserve data)
./shutdown.sh full

# Clean shutdown (remove everything including data)
./shutdown.sh clean

# Backup databases only
./shutdown.sh backup
```

## 🐳 Docker Deployment (Development)

### Docker Compose Setup

#### Quick Start
```bash
# Start all services
./deploy.sh start

# View service status
./deploy.sh status

# View logs
./deploy.sh logs

# Stop all services
./deploy.sh stop
```

#### Service URLs (Docker Compose)
- **Frontend**: http://localhost:3000
- **User Service**: http://localhost:8001
- **Catalog Service**: http://localhost:8002
- **Order Service**: http://localhost:8003

## ⚙️ Configuration Management

### Environment Variables

#### Kubernetes (Production)
Environment variables are managed through ConfigMaps and Secrets:

```yaml
# ConfigMap (k8s-manifests/01-config.yaml)
data:
  ACCESS_TOKEN_EXPIRE_MINUTES: "60"
  CORS_ORIGINS: "https://senecabooks.local"
  USER_SERVICE_URL: "http://user-service:8000"

# Secret (k8s-manifests/01-config.yaml)
stringData:
  SECRET_KEY: "seneca-bookstore-jwt-secret-key-2025-production"
```

#### Service Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | JWT signing secret | Required |
| `DATABASE_URL` | SQLite database path | `sqlite:///./users.db` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiration | `60` |
| `CORS_ORIGINS` | Allowed CORS origins | `*` |

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Minikube Issues

**Issue**: Minikube fails to start
```bash
# Solution: Delete and recreate cluster
minikube delete
minikube start --driver=docker --memory=8192 --cpus=4
```

**Issue**: Domain not resolving
```bash
# Solution: Update hosts file
echo "$(minikube ip) senecabooks.local" | sudo tee -a /etc/hosts
```

#### Application Issues

**Issue**: Services can't communicate
```bash
# Kubernetes: Check service endpoints
kubectl get endpoints -n seneca-bookstore

# Docker: Check network
docker-compose ps
```

### Debug Commands

#### Kubernetes Debugging
```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n seneca-bookstore

# Access pod shell
kubectl exec -it deployment/user-service -n seneca-bookstore -- bash

# Port forward for local debugging
kubectl port-forward deployment/user-service 8001:8000 -n seneca-bookstore
```

---

## 🧪 Testing and Validation

### Comprehensive Testing Suite

#### Automated Test Execution
```bash
# Run all tests against the deployed application
./test.sh

# Test specific deployment target
./test.sh k8s          # Test Kubernetes deployment
./test.sh docker       # Test Docker Compose deployment
./test.sh both         # Test both deployments

# Run specific test types
./test.sh --unit-only     # Unit tests only
./test.sh --load-only     # Load tests only
./test.sh --integration   # Integration tests only
./test.sh --monitoring    # Monitoring stack tests
```

#### Test Types Available

**1. Unit Tests**
- pytest suite for authentication endpoints
- Comprehensive test coverage for /register and /login
- Input validation and edge case testing
- Authentication flow validation

**2. Load Testing**
- High-concurrency testing for /books and /orders endpoints
- Configurable user count and request volume
- Performance analytics and response time tracking
- Mixed workload simulation

**3. Integration Tests**
- End-to-end user workflow validation
- Cross-service communication testing
- Authentication flow from registration to protected endpoints
- Real-world scenario simulation

**4. Monitoring Validation**
- Prometheus metrics endpoint testing
- Grafana dashboard accessibility
- Service health check validation
- Monitoring stack connectivity

#### Performance Testing
```bash
# Load test data into all services
python scripts/load_test_data.py

# Quick performance check
./test.sh --quick

# Generate additional test data for load testing
python scripts/generate_test_data.py --output-file test_data_large.json --count 1000
```

### Test Environment Setup
```bash
# Install test dependencies
pip install pytest requests

# Run tests in the background while monitoring
./test.sh --monitoring &
watch kubectl get pods -n seneca-bookstore
```

---

## 📊 Monitoring and Observability

### Enterprise Monitoring Stack

#### Prometheus Configuration
- **Metrics Collection**: All services expose `/metrics` endpoints
- **Scrape Intervals**: 15-second intervals for real-time monitoring
- **Alert Rules**: Pre-configured alerts for service health
- **Data Retention**: 15 days of metrics data stored locally

#### Grafana Dashboards
- **Pre-configured Dashboard**: "Seneca Book Store Overview"
- **Service Metrics**: Request rates, response times, error rates
- **Business Metrics**: User registrations, orders, book views
- **System Health**: Pod status, resource utilization

#### Accessing Monitoring Tools
```bash
# Prometheus (metrics and alerting)
open https://senecabooks.local/prometheus

# Grafana (dashboards and visualization)
open https://senecabooks.local/grafana
# Login: admin / admin123
```

#### Custom Metrics Tracked
- **User Service**: 
  - `user_registrations_total`: Total user registrations
  - `user_logins_total`: Total successful logins
  - `user_login_failures_total`: Failed login attempts

- **Catalog Service**:
  - `catalog_books_browsed_total`: Book browsing activity
  - `catalog_books_viewed_total`: Individual book views
  - `catalog_search_queries_total`: Search activity

- **Order Service**:
  - `orders_created_total`: Orders created (by type: buy/rent)
  - `orders_viewed_total`: Order detail views
  - `orders_status_changes_total`: Order status updates

#### Monitoring Service Health
```bash
# Check all service metrics endpoints
curl https://senecabooks.local/api/user/metrics
curl https://senecabooks.local/api/catalog/metrics
curl https://senecabooks.local/api/order/metrics

# Monitor Prometheus targets
curl https://senecabooks.local/prometheus/api/v1/targets

# Test Grafana API
curl https://senecabooks.local/grafana/api/health
```

### Monitoring Deployment and RBAC
- **Dedicated Service Account**: monitoring-service with cluster-wide read access
- **ClusterRole**: Permissions for cross-namespace service discovery
- **Security**: Monitoring services isolated with NetworkPolicies
- **Persistence**: Prometheus data persisted across pod restarts

### Alert Management
- **Service Health Alerts**: Automatic alerts when services become unhealthy
- **Performance Thresholds**: Alerts for high response times or error rates
- **Resource Monitoring**: Alerts for high CPU/memory usage
- **Custom Business Alerts**: Alerts for unusual business metric patterns

---

## � External Book Integration Features

### Open Library API Integration
The Seneca Book Store now includes powerful external book discovery capabilities through Open Library API integration:

#### Key Features
- **📚 Massive Book Database**: Access to millions of books from Open Library
- **🔍 Advanced Search**: Search by title, author, ISBN, or keywords  
- **📖 Category Browsing**: Browse popular subjects like science fiction, history, romance
- **🖼️ Rich Metadata**: Book covers, publication info, author details, and subject tags
- **📥 Smart Import**: Admin-only feature to import external books with custom pricing
- **🆓 Free & Open**: No API keys required, completely free to use

#### New API Endpoints
```bash
# Search external books
GET /api/catalog/books/external/search?q={query}&limit=20&offset=0

# Browse by subject
GET /api/catalog/books/external/subject/{subject}?limit=20&offset=0

# Get popular subjects
GET /api/catalog/books/external/subjects

# Get book by ISBN
GET /api/catalog/books/external/isbn/{isbn}

# Import book to catalog (Admin only)
POST /api/catalog/books/import
```

#### Frontend Integration
- **New "Discover" Page**: Dedicated interface for browsing external books
- **Visual Book Browser**: Rich card-based layout with covers and metadata
- **Category Navigation**: Quick access to 20+ popular book categories
- **Smart Import Modal**: Easy-to-use interface for importing books to catalog
- **Search & Pagination**: Full-featured search with pagination support

#### Usage Examples
```bash
# Test external book search
curl "https://senecabooks.local/api/catalog/books/external/search?q=python%20programming&limit=5"

# Browse science fiction books
curl "https://senecabooks.local/api/catalog/books/external/subject/science_fiction?limit=10"

# Get book details by ISBN
curl "https://senecabooks.local/api/catalog/books/external/isbn/9780132269933"
```

#### Database Enhancements
The catalog service database now includes new fields to support external book integration:
- `cover_url`: Book cover image URL
- `source`: Data source identifier (local, open_library, etc.)
- `external_key`: External API key/identifier for tracking

---

## �📞 Support and Documentation

### Additional Resources
- **API Documentation**: Available at each service's `/docs` endpoint (catalog service now includes external book endpoints!)
- **Kubernetes Dashboard**: `minikube dashboard`
- **Application Logs**: `./deploy.sh --k8s logs <service>`
- **Health Monitoring**: All services have `/health` endpoints
- **Monitoring Access**: Prometheus and Grafana via Ingress routes
- **Test Documentation**: Comprehensive test suite with `./test.sh --help`
- **External Book Discovery**: Access via https://senecabooks.local/discover

### New Features Testing
- **External Book Search**: Use the "Discover" page to search millions of books
- **Category Browsing**: Browse books by popular subjects
- **Admin Import**: Test book import functionality (admin users only)
- **Cover Images**: Verify book cover image loading and fallbacks
- **API Integration**: Test external API endpoints for responsiveness

### Performance Optimization
- **Resource Limits**: All pods have defined CPU/memory limits
- **Health Checks**: Liveness and readiness probes for zero-downtime deployments
- **Horizontal Scaling**: Services can be scaled using `kubectl scale`
- **Monitoring Insights**: Use Grafana dashboards to identify performance bottlenecks
- **External API Caching**: Open Library API responses are efficiently handled with async processing

### Getting Help
- Check application logs first: `./deploy.sh logs <service>`
- Verify service connectivity: `./test.sh --integration`
- Test monitoring stack: `./test.sh --monitoring`
- Review resource usage: Check Grafana dashboards
- Run comprehensive tests: `./test.sh`
- Test external book integration: Visit `/discover` page and try searching/browsing

This guide covers comprehensive deployment scenarios including testing, monitoring, and the new external book integration features. For specific issues not covered here, check the service logs, run the test suite, and review monitoring dashboards for detailed error messages and performance insights.