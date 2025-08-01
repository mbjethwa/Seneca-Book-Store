# 🚀 Deployment Guide - Seneca Book Store

This comprehensive guide covers all deployment options for the Seneca Book Store microservices application, from local development to production Kubernetes deployment using the **unified deployment script**.

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Unified Deployment Script](#unified-deployment-script)
4. [Kubernetes Deployment (Production)](#kubernetes-deployment-production)
5. [Docker Deployment (Development)](#docker-deployment-development)
6. [Configuration Management](#configuration-management)
7. [Troubleshooting](#troubleshooting)

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

## 📞 Support and Documentation

### Additional Resources
- **API Documentation**: Available at each service's `/docs` endpoint
- **Kubernetes Dashboard**: `minikube dashboard`
- **Application Logs**: `./deploy.sh --k8s logs <service>`
- **Health Monitoring**: All services have `/health` endpoints

### Getting Help
- Check application logs first
- Verify service connectivity
- Ensure proper configuration
- Review resource usage

This guide covers comprehensive deployment scenarios. For specific issues not covered here, check the service logs and Kubernetes events for detailed error messages.