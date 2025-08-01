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
```

### Frontend Service Setup

```bash
cd frontend-service
npm install

# Start development server
npm start
# Frontend available at http://localhost:3000

# Build for production
npm run build
```

## Docker Deployment

### Phase 5: Complete Dockerization ✅

All services are fully containerized with optimized Dockerfiles:

#### Backend Services (FastAPI)
- **Base Image**: `python:3.11-slim` for optimal size and security
- **Dependencies**: Installed via `requirements.txt` with caching
- **Runtime**: Uvicorn ASGI server on port 8000
- **Health Checks**: Built-in health endpoints for monitoring

#### Frontend Service (React + Nginx)
- **Build Stage**: Node.js 18 for compiling React application
- **Production Stage**: Nginx Alpine for serving static files
- **Optimization**: Multi-stage build reduces final image size

### Automated Deployment (Recommended)

Use the provided deployment script for one-command deployment:

```bash
# Make script executable
chmod +x deploy.sh

# Deploy all services
./deploy.sh

# Deploy with cleanup (removes existing containers)
./deploy.sh --clean

# Deploy only Docker Compose (skip Kubernetes)
./deploy.sh --docker

# Show help
./deploy.sh --help
```

### Manual Docker Commands

If you prefer to build and run containers manually:

```bash
# Build all service images
docker build -t seneca-user-service:latest user-service/
docker build -t seneca-catalog-service:latest catalog-service/
docker build -t seneca-order-service:latest order-service/
docker build -t seneca-frontend-service:latest frontend-service/

# Run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Service URLs

After successful deployment, services will be available at:

### Docker Compose
- **Frontend**: http://localhost:3000
- **User Service**: http://localhost:8001
- **Catalog Service**: http://localhost:8002
- **Order Service**: http://localhost:8003

For additional support, check the main README.md file or project documentation.
