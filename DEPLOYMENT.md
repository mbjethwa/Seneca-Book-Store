# Deployment Guide - Seneca Book Store

This guide covers different deployment options for the Seneca Book Store microservices application.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Development](#local-development)
3. [Docker Deployment](#docker-deployment)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [Production Considerations](#production-considerations)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **kubectl**: Version 1.25+
- **Node.js**: Version 18+ (for local frontend development)
- **Python**: Version 3.11+ (for local backend development)

### Optional Tools
- **Helm**: For advanced Kubernetes deployments
- **Minikube/Kind**: For local Kubernetes testing

## Local Development

### Backend Services Setup

Each backend service can be run independently:

```bash
# User Service (with authentication)
cd user-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set environment variables
export SECRET_KEY="your-super-secret-jwt-key-change-in-production-please"
export DATABASE_URL="sqlite:///./users.db"

python main.py
# Service available at http://localhost:8000

# Test the endpoints:
# Register: curl -X POST "http://localhost:8000/register" -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123","full_name":"Test User"}'
# Login: curl -X POST "http://localhost:8000/login" -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123"}'

# Catalog Service (with book management)
cd ../catalog-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="sqlite:///./catalog.db"
export USER_SERVICE_URL="http://localhost:8001"
export ADMIN_EMAILS="admin@seneca.ca,admin@example.com"

python main.py
# Service available at http://localhost:8000

# Test the endpoints:
# List books: curl "http://localhost:8000/books"
# Get categories: curl "http://localhost:8000/categories"

# Repeat for order-service (basic health checks only)
```

### Frontend Service Setup

```bash
cd frontend-service
npm install
npm start
# Application available at http://localhost:3000
```

### Environment Variables

Create `.env` files in each service directory for local configuration:

**User Service (.env):**
```env
SECRET_KEY=your-super-secret-jwt-key-change-in-production-please
DATABASE_URL=sqlite:///./users.db
ACCESS_TOKEN_EXPIRE_MINUTES=60
PORT=8000
DEBUG=true
LOG_LEVEL=info
```

**Catalog Service (.env):**
```env
DATABASE_URL=sqlite:///./catalog.db
USER_SERVICE_URL=http://localhost:8001
ADMIN_EMAILS=admin@seneca.ca,admin@example.com
PORT=8000
DEBUG=true
LOG_LEVEL=info
```

**Other Backend Services (.env):**
```env
PORT=8000
DEBUG=true
LOG_LEVEL=info
```

**Frontend Service (.env):**
```env
REACT_APP_USER_SERVICE_URL=http://localhost:8001
REACT_APP_CATALOG_SERVICE_URL=http://localhost:8002
REACT_APP_ORDER_SERVICE_URL=http://localhost:8003
```

## Docker Deployment

### Single Service Deployment

Build and run individual services:

```bash
# Backend services
cd user-service
docker build -t user-service:latest .
docker run -p 8001:8000 user-service:latest

cd ../catalog-service
docker build -t catalog-service:latest .
docker run -p 8002:8000 catalog-service:latest

cd ../order-service
docker build -t order-service:latest .
docker run -p 8003:8000 order-service:latest

# Frontend service
cd ../frontend-service
docker build -t frontend-service:latest .
docker run -p 3000:80 frontend-service:latest
```

### Docker Compose Deployment

Create `docker-compose.yml` in the root directory:

```yaml
version: '3.8'

services:
  user-service:
    build: ./user-service
    ports:
      - "8001:8000"
    environment:
      - PORT=8000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  catalog-service:
    build: ./catalog-service
    ports:
      - "8002:8000"
    environment:
      - PORT=8000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  order-service:
    build: ./order-service
    ports:
      - "8003:8000"
    environment:
      - PORT=8000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend-service:
    build: ./frontend-service
    ports:
      - "3000:80"
    depends_on:
      - user-service
      - catalog-service
      - order-service
    environment:
      - REACT_APP_USER_SERVICE_URL=http://localhost:8001
      - REACT_APP_CATALOG_SERVICE_URL=http://localhost:8002
      - REACT_APP_ORDER_SERVICE_URL=http://localhost:8003
```

Run with Docker Compose:
```bash
docker-compose up -d
```

## Kubernetes Deployment

### Prerequisites

Ensure you have a Kubernetes cluster running:

```bash
# Check cluster status
kubectl cluster-info

# Verify nodes are ready
kubectl get nodes
```

### Build and Push Images

```bash
# Build all images
docker build -t your-registry/user-service:latest ./user-service
docker build -t your-registry/catalog-service:latest ./catalog-service
docker build -t your-registry/order-service:latest ./order-service
docker build -t your-registry/frontend-service:latest ./frontend-service

# Push to registry
docker push your-registry/user-service:latest
docker push your-registry/catalog-service:latest
docker push your-registry/order-service:latest
docker push your-registry/frontend-service:latest
```

### Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s-manifests/

# Check deployment status
kubectl get deployments
kubectl get services
kubectl get pods

# Get service URLs
kubectl get services
```

### Access Applications

```bash
# Get frontend service URL
kubectl get service frontend-service

# Port forward for local access (if needed)
kubectl port-forward service/frontend-service 3000:80
kubectl port-forward service/user-service 8001:8000
kubectl port-forward service/catalog-service 8002:8000
kubectl port-forward service/order-service 8003:8000
```

## Production Considerations

### Security
- Use secrets for sensitive configuration
- Implement proper RBAC
- Enable network policies
- Use TLS/SSL certificates

### Monitoring
- Deploy monitoring stack (Prometheus + Grafana)
- Set up log aggregation (ELK stack)
- Configure alerting rules

### Scaling
- Configure horizontal pod autoscalers
- Set resource limits and requests
- Use cluster autoscaling

### Backup and Recovery
- Regular database backups
- Disaster recovery procedures
- Multi-region deployment for high availability

### Example Production Configuration

```yaml
# Production values
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: user-service
        image: user-service:v1.0.0
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## Troubleshooting

### Common Issues

**Service not accessible:**
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>

# Check service configuration
kubectl get service <service-name>
kubectl describe service <service-name>

# Check logs
kubectl logs <pod-name>
```

**Image pull errors:**
```bash
# Verify image exists
docker images | grep <service-name>

# Check image pull policy
kubectl describe pod <pod-name>
```

**Port conflicts:**
```bash
# Check what's running on ports
netstat -tulpn | grep <port>

# Change port mappings in docker-compose.yml or use different ports
```

### Debugging Commands

```bash
# Enter running container
kubectl exec -it <pod-name> -- /bin/bash

# Check service endpoints
kubectl get endpoints

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top pods
kubectl top nodes
```

### Performance Optimization

- Monitor response times and error rates
- Optimize Docker image sizes
- Use multi-stage builds
- Implement caching strategies
- Configure resource limits appropriately

For additional support, check the application logs and Kubernetes events for specific error messages.
