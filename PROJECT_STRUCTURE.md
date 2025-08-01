# Project Structure Overview

```
Seneca Book Store/
├── .git/                          # Git repository
├── .gitignore                     # Git ignore rules
├── README.md                      # Main project documentation
├── DEPLOYMENT.md                  # Detailed deployment guide
├── deploy.sh                      # Automated deployment script
├── user-service/                  # User management microservice ✅ COMPLETE
│   ├── main.py                    # FastAPI application with auth
│   ├── database.py                # SQLAlchemy models and DB setup
│   ├── auth.py                    # JWT token utilities
│   ├── schemas.py                 # Pydantic models
│   ├── crud.py                    # Database operations
│   ├── test_main.py               # Unit tests
│   ├── requirements.txt           # Python dependencies (with auth libs)
│   ├── Dockerfile                 # Docker configuration
│   └── .env.example               # Environment variables template
├── catalog-service/               # Book catalog microservice (basic)
│   ├── main.py                    # FastAPI application
│   ├── requirements.txt           # Python dependencies
│   └── Dockerfile                 # Docker configuration
├── order-service/                 # Order processing microservice (basic)
│   ├── main.py                    # FastAPI application
│   ├── requirements.txt           # Python dependencies
│   └── Dockerfile                 # Docker configuration
├── frontend-service/              # React frontend application
│   ├── public/                    # Static assets
│   ├── src/                       # React source code
│   ├── package.json               # Node.js dependencies
│   └── Dockerfile                 # Docker configuration
└── k8s-manifests/                 # Kubernetes deployment files
    ├── user-service.yaml          # User service K8s manifest (with env vars)
    ├── catalog-service.yaml       # Catalog service K8s manifest
    ├── order-service.yaml         # Order service K8s manifest
    └── frontend-service.yaml      # Frontend service K8s manifest
```

## Phase 1 Implementation Status ✅

### User Service - COMPLETE
- ✅ **Authentication System**: JWT-based authentication
- ✅ **User Registration**: `/register` endpoint with email/password
- ✅ **User Login**: `/login` endpoint returning JWT tokens
- ✅ **Protected Routes**: `/me` endpoint requiring authentication
- ✅ **Password Security**: bcrypt hashing
- ✅ **Database**: SQLite with SQLAlchemy ORM
- ✅ **Testing**: Comprehensive unit tests
- ✅ **Environment Config**: Secure configuration management

### Other Services - Basic Setup
- ✅ **Catalog Service**: Health check endpoints only
- ✅ **Order Service**: Health check endpoints only
- ✅ **Frontend Service**: React app ready for integration

## Authentication Flow

1. **User Registration**:
   ```bash
   POST /register
   {
     "email": "user@example.com",
     "password": "securepassword",
     "full_name": "John Doe"
   }
   ```

2. **User Login**:
   ```bash
   POST /login
   {
     "email": "user@example.com", 
     "password": "securepassword"
   }
   # Returns: {"access_token": "jwt_token", "token_type": "bearer"}
   ```

3. **Access Protected Routes**:
   ```bash
   GET /me
   Authorization: Bearer <jwt_token>
   ```

## Quick Start Commands

```bash
# Make deployment script executable (if not already done)
chmod +x deploy.sh

# Deploy everything with Docker Compose
./deploy.sh --docker

# Deploy to Kubernetes  
./deploy.sh --k8s

# Deploy to both Docker Compose and Kubernetes
./deploy.sh

# Clean up and redeploy
./deploy.sh --clean

# Test the user service locally
cd user-service
pip install -r requirements.txt
python main.py

# Run tests
cd user-service
pytest test_main.py
```

## Next Phases

- **Phase 2**: Catalog Service - Book inventory management
- **Phase 3**: Order Service - Order processing
- **Phase 4**: Frontend Integration - Connect React app to backend APIs
- **Phase 5**: Advanced Features - Search, recommendations, etc.
