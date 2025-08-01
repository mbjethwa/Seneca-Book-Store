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
├── catalog-service/               # Book catalog microservice ✅ COMPLETE
│   ├── main.py                    # FastAPI application with book management
│   ├── database.py                # SQLAlchemy models and DB setup
│   ├── auth.py                    # Admin authentication utilities
│   ├── schemas.py                 # Pydantic models for books
│   ├── crud.py                    # Database operations
│   ├── test_main.py               # Unit tests
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Docker configuration
│   └── .env.example               # Environment variables template
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

## Phase 1 & 2 Implementation Status ✅

### User Service - COMPLETE ✅
- ✅ **Authentication System**: JWT-based authentication
- ✅ **User Registration**: `/register` endpoint with email/password
- ✅ **User Login**: `/login` endpoint returning JWT tokens
- ✅ **Protected Routes**: `/me` endpoint requiring authentication
- ✅ **Password Security**: bcrypt hashing
- ✅ **Database**: SQLite with SQLAlchemy ORM
- ✅ **Testing**: Comprehensive unit tests
- ✅ **Environment Config**: Secure configuration management

### Catalog Service - COMPLETE ✅
- ✅ **Book Management**: Full CRUD operations for books
- ✅ **Admin Authentication**: Integration with User Service for admin access
- ✅ **Advanced Search**: Search by title, author, description with filters
- ✅ **Inventory Tracking**: Stock quantity and availability management
- ✅ **Pricing System**: Both purchase and rental pricing
- ✅ **Data Validation**: Comprehensive validation with Pydantic
- ✅ **Database**: SQLite with SQLAlchemy ORM
- ✅ **Testing**: Full test suite with mocked authentication
- ✅ **Sample Data**: Seed endpoint for development

### Other Services - Basic Setup
- ✅ **Order Service**: Health check endpoints only
- ✅ **Frontend Service**: React app ready for integration

## Book Management Flow (Phase 2)

1. **Admin Setup**:
   ```bash
   # Register as admin (use admin email)
   POST /register
   {
     "email": "admin@seneca.ca",
     "password": "adminpass123",
     "full_name": "Admin User"
   }
   ```

2. **Admin Authentication**:
   ```bash
   POST /login
   {
     "email": "admin@seneca.ca", 
     "password": "adminpass123"
   }
   # Returns: {"access_token": "jwt_token", "token_type": "bearer"}
   ```

3. **Book Management**:
   ```bash
   # Create sample data
   POST /seed-data
   Authorization: Bearer <jwt_token>
   
   # Add new book
   POST /books
   Authorization: Bearer <jwt_token>
   {
     "title": "Python Programming",
     "author": "John Smith",
     "price": 49.99,
     "rent_price": 5.99,
     "category": "Programming"
   }
   
   # Search books
   GET /books?search=Python&category=Programming
   ```

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

- **Phase 3**: Order Service - Order processing and rental management
- **Phase 4**: Frontend Integration - Connect React app to backend APIs
- **Phase 5**: Advanced Features - Recommendations, reviews, advanced search
