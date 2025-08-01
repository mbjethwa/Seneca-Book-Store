# Seneca Book Store - Microservices Architecture

A modern microservices-based bookstore application built with FastAPI backend services and React frontend.

## Architecture Overview

```
├── user-service/          # User management service (FastAPI)
├── catalog-service/       # Book catalog service (FastAPI)
├── order-service/         # Order management service (FastAPI)
├── frontend-service/      # React frontend application
└── k8s-manifests/        # Kubernetes deployment manifests
```

## Services

### Backend Services (FastAPI)
- **User Service**: Handles user authentication and profile management
- **Catalog Service**: Manages book inventory and catalog
- **Order Service**: Processes orders and transactions

All backend services:
- Run on port 8000
- Include health check endpoints (`/` and `/health`)
- Built with FastAPI and uvicorn
- Containerized with Docker

### Frontend Service (React)
- Modern React application
- Serves the user interface
- Runs on port 3000 (development) / 80 (production)
- Built with Create React App

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Python 3.11+ (for local development)
- kubectl (for Kubernetes deployment)

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd "Seneca Book Store"
   ```

2. **Run individual services:**

   **Backend Services:**
   ```bash
   # User Service
   cd user-service
   pip install -r requirements.txt
   python main.py

   # Catalog Service  
   cd catalog-service
   pip install -r requirements.txt
   python main.py

   # Order Service
   cd order-service
   pip install -r requirements.txt
   python main.py
   ```

   **Frontend Service:**
   ```bash
   cd frontend-service
   npm install
   npm start
   ```

3. **Using Docker Compose:**
   ```bash
   ./deploy.sh
   ```

### Production Deployment

Run the deployment script:
```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
- Build all Docker images
- Deploy to Kubernetes cluster
- Set up all services with proper networking

## API Endpoints

### User Service (Port 8000)
- `GET /` - Health check
- `GET /health` - Service health status

### Catalog Service (Port 8000)
- `GET /` - Health check
- `GET /health` - Service health status

### Order Service (Port 8000)
- `GET /` - Health check
- `GET /health` - Service health status

### Frontend Service
- Accessible via LoadBalancer on port 80

## Development Guide

### Adding New Features

1. **Backend Services:**
   - Add new endpoints to respective `main.py` files
   - Update requirements.txt if new dependencies needed
   - Rebuild Docker images

2. **Frontend:**
   - Add new components in `src/components/`
   - Update routing in `src/App.js`
   - Rebuild for production deployment

### Testing

Each service can be tested independently:

```bash
# Test backend services
curl http://localhost:8000/health

# Test frontend
curl http://localhost:3000
```

## Monitoring

Health check endpoints are available for all services:
- User Service: `http://user-service:8000/health`
- Catalog Service: `http://catalog-service:8000/health`
- Order Service: `http://order-service:8000/health`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
