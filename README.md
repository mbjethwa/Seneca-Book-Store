# 📚 Seneca Book Store - Complete Microservices Application

A modern, full-stack microservices application for managing a book store with authentication, catalog management, order processing, and a beautiful React frontend.

## 🎯 Project Overview

Seneca Book Store is a comprehensive e-commerce platform built with microservices architecture, featuring:
- **User Authentication & Management**
- **Book Catalog & Inventory Management**
- **Order Processing (Buy/Rent)**
- **Modern React Frontend with Admin Dashboard**
- **Microservices with FastAPI**
- **JWT Authentication**
- **Docker & Kubernetes Deployment**

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Frontend       │    │  User Service   │    │ Catalog Service │
│  (React)        │◄──►│  (Auth & JWT)   │◄──►│ (Books & Admin) │
│  Port: 3000     │    │  Port: 8001     │    │  Port: 8002     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       └───────────────────────┼──────┐
         │                                               │      │
         └─────────────────────────────────────────────┐ │      │
                                                       ▼ ▼      ▼
                                              ┌─────────────────┐
                                              │  Order Service  │
                                              │ (Buy/Rent Logic)│
                                              │  Port: 8003     │
                                              └─────────────────┘
```

## ✨ Features Implemented

### Phase 0: Project Structure ✅
- ✅ Microservices architecture with FastAPI backends
- ✅ React frontend application
- ✅ Docker containerization
- ✅ Kubernetes deployment manifests
- ✅ CI/CD deployment scripts

### Phase 1: User Service (Authentication) ✅
- ✅ JWT-based authentication system
- ✅ User registration and login endpoints
- ✅ Password hashing with bcrypt
- ✅ Protected routes with token validation
- ✅ SQLite database with SQLAlchemy ORM

### Phase 2: Catalog Service (Books & Inventory) ✅
- ✅ Full CRUD operations for book management
- ✅ Admin-only access with User Service integration
- ✅ Advanced search and filtering capabilities
- ✅ Inventory tracking with stock management
- ✅ Both purchase and rental pricing systems

### Phase 3: Order Service (Buy or Rent) ✅
- ✅ Complete order processing system
- ✅ Buy or rent functionality with different pricing
- ✅ User authentication integration
- ✅ Real-time stock validation via Catalog Service
- ✅ Rental management with return tracking

### Phase 4: Frontend (React) ✅
- ✅ **Modern, Responsive UI** with warm color scheme
- ✅ **Authentication Flow** - Login/Register with JWT
- ✅ **Book Catalog** - Browse, search, and filter books
- ✅ **Order Management** - Buy/Rent books with real-time updates
- ✅ **Admin Dashboard** - Complete book and order management
- ✅ **Order History** - Track purchases and rentals
- ✅ **Rental Returns** - Easy book return functionality
- ✅ **Professional Design** - Google Fonts, animations, and modern UI components

### Phase 5: Dockerization ✅
- ✅ **Backend Services**: Optimized Dockerfiles with `python:3.11-slim`
- ✅ **Frontend Service**: Multi-stage build with Node.js + Nginx
- ✅ **Container Orchestration**: Complete Docker Compose setup
- ✅ **Production Ready**: Health checks, proper networking, and environment configuration

### Phase 6: Kubernetes Setup ✅
- ✅ **Minikube Deployment**: Complete Kubernetes orchestration on Minikube
- ✅ **Service Mesh**: Deployments and Services for all microservices
- ✅ **Configuration Management**: ConfigMaps and Secrets for environment variables
- ✅ **Persistent Storage**: PVC/PV for database persistence across restarts
- ✅ **Ingress with TLS**: HTTPS access via `https://senecabooks.local` with cert-manager
- ✅ **Automated Deployment**: Comprehensive scripts for deploy and shutdown
- ✅ **Health Monitoring**: Liveness and readiness probes for all services

### Phase 7: Security Operations ✅
- ✅ **Comprehensive Logging**: All API calls logged with method, path, user, and status code
- ✅ **RBAC (Role-Based Access Control)**: 
  - user-service: Access to secrets and ConfigMaps
  - catalog-service: Read-only access with limited permissions
  - order-service: Standard service access permissions
  - frontend-service: Minimal read-only access
- ✅ **Network Policies**: 
  - Default deny-all traffic policy
  - Allow internal communication between services only
  - Block external access except via Ingress controller
  - Service-specific communication rules
- ✅ **Security Headers**: JWT token validation and secure communication
- ✅ **Service Accounts**: Dedicated service accounts for each microservice

### Phase 8: Testing and Monitoring ✅
- ✅ **Comprehensive Test Suite**: 
  - pytest unit tests for authentication endpoints (/register, /login)
  - Load testing script for high-traffic endpoints (/books, /orders)
  - Integration tests for complete user workflows
  - Performance validation and concurrent request handling
- ✅ **Enterprise Monitoring Stack**: 
  - **Prometheus**: Complete metrics collection with custom dashboards
  - **Grafana**: Pre-configured dashboards for service health monitoring
  - **Service Metrics**: Request duration, response status, and business metrics
  - **Real-time Alerts**: Service health and performance alerts
- ✅ **Production Observability**:
  - Custom metrics for user registrations, logins, book browsing, and order creation
  - Request/response tracking across all microservices
  - Performance monitoring with histogram metrics
  - Health check endpoints with monitoring integration
- ✅ **Automated Testing Pipeline**:
  - Unified test runner script (`test.sh`) for all test types
  - Support for both Docker and Kubernetes deployments
  - Comprehensive test reporting and analytics

### Phase 9: External Book Data Integration ✅
- ✅ **Open Library API Integration**: 
  - **Massive Book Database**: Access to millions of books from Open Library
  - **Rich Metadata**: Book covers, authors, publication info, ISBNs, and subjects
  - **Free & Open Source**: No authentication required, completely free to use
- ✅ **External Book Discovery**:
  - **Advanced Search**: Search by title, author, ISBN across millions of books
  - **Category Browsing**: Browse by popular subjects (science fiction, history, romance, etc.)
  - **Book Import System**: Admin-only import of external books to local catalog
  - **Cover Images**: Automatic cover image integration from Open Library
- ✅ **Enhanced Frontend**:
  - **Discover Page**: New dedicated interface for browsing external books
  - **Visual Book Browser**: Rich card-based interface with covers and metadata
  - **Smart Import Modal**: Easy-to-use import interface for admins
  - **Subject Categories**: Quick access to popular book categories
- ✅ **Intelligent Data Management**:
  - **Source Tracking**: Track data origin (local vs. external)
  - **Duplicate Prevention**: Prevent duplicate imports via ISBN checking
  - **Flexible Pricing**: Set custom pricing for imported books
  - **Metadata Enhancement**: Automatic population of descriptions and categories

### Phase 10: Comprehensive Test Data Integration ✅
- ✅ **Complete Test Dataset**: 
  - **7 User Accounts**: 2 admin users, 5 regular users with realistic profiles
  - **48 Book Catalog**: Programming, classic literature, and business books with ISBNs
  - **75 Sample Orders**: Purchase and rental transactions across all users
  - **Realistic Data**: Valid ISBNs, cover URLs, and comprehensive metadata
- ✅ **Automated Data Loading**:
  - **Test Data Generator**: Comprehensive Python script for realistic data generation
  - **Smart Data Loader**: Async HTTP client for efficient API data loading
  - **Environment Support**: Works with both Docker and Kubernetes deployments
  - **Deployment Integration**: Automatic test data loading during deployment
- ✅ **User-Friendly Management**:
  - **Quick Start Script**: One-command data generation and loading
  - **Comprehensive Documentation**: Complete TEST_DATA.MD with all credentials
  - **Multiple Access Methods**: Manual scripts, deployment integration, quick start
  - **Verification System**: Built-in data loading verification and error handling
- ✅ **Production-Ready Demo Data**:
  - **Sample Credentials**: Pre-configured admin and user accounts for immediate testing
  - **Rich Book Catalog**: Three categories with realistic pricing and metadata
  - **Order History**: Comprehensive transaction data showcasing buy/rent functionality
  - **External Integration**: Mock data demonstrating Open Library API integration

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ and npm
- Python 3.8+
- Docker and Docker Compose
- **Kubernetes**: kubectl, minikube, helm (for K8s deployment)
- Git

## 🚀 Quick Start

The project now includes a **unified deployment script** that supports both Docker Compose and Kubernetes deployments.

### Option 1: Kubernetes Deployment (Recommended)
```bash
git clone <repository-url>
cd "Seneca Book Store"

# Deploy everything on Minikube with one command
./deploy.sh --k8s deploy

# Access the application
open https://senecabooks.local
```

### Option 2: Docker Compose (Development)
```bash
git clone <repository-url>
cd "Seneca Book Store"

# Access the application
open http://localhost:3000
```

### Option 3: Both Deployments (Full Testing)
```bash
git clone <repository-url>
cd "Seneca Book Store"

# Deploy with both Docker Compose and Kubernetes
./deploy.sh --both deploy

# Access applications:
# - Docker Compose: http://localhost:3000
# - Kubernetes: https://senecabooks.local
```

### 3. Access the Application
- **Production (K8s)**: https://senecabooks.local (Secure HTTPS with TLS)
- **Development**: http://localhost:3000
- **New Feature**: Access the **Discover** page to browse millions of books from Open Library!

## 🔒 Security & Best Practices

Seneca Book Store is built with **security-first architecture** and follows industry best practices:

### 🛡️ Security Features
- **🔐 JWT Authentication**: Secure token-based authentication with cryptographically secure SECRET_KEY
- **🔑 Password Security**: bcrypt hashing with salt for all user passwords
- **🚫 Zero-Trust Network**: Kubernetes network policies with explicit allow rules only
- **🔒 RBAC**: Role-based access control with least-privilege principles
- **🌐 TLS/HTTPS**: End-to-end encryption for all communications
- **📊 Audit Logging**: Comprehensive logging of all user actions and API calls
- **🛠️ Secret Management**: Kubernetes Secrets for sensitive configuration
- **🚨 Security Monitoring**: Prometheus metrics for security events

### 🔧 Environment Security
```bash
# Generate secure SECRET_KEY
openssl rand -base64 32

# Example secure environment configuration
SECRET_KEY=<generated-secure-key>
DATABASE_URL=postgresql://user:pass@host/db  # Use PostgreSQL in production
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

### 📋 Security Checklist
- ✅ **Secrets Management**: All sensitive data stored in Kubernetes Secrets or environment variables
- ✅ **Input Validation**: Comprehensive validation and sanitization of all user inputs
- ✅ **SQL Injection Prevention**: Parameterized queries and ORM usage
- ✅ **XSS Protection**: Output encoding and secure headers
- ✅ **Resource Limits**: CPU and memory limits to prevent DoS attacks
- ✅ **Error Handling**: Secure error messages without information disclosure
- ✅ **Dependency Scanning**: Regular security updates and vulnerability scanning

### 🚨 Security Testing
```bash
# Generate secure test credentials (never use hardcoded passwords)
python scripts/generate_secure_credentials.py

# Run security audit
pip-audit  # Python dependencies
npm audit  # Node.js dependencies
```

For detailed security information, see [SECURITY.md](SECURITY.md).

## 📊 Test Data & Sample Accounts

The Seneca Book Store comes with comprehensive test data to demonstrate all features. **Test data is automatically loaded during deployment**, but you can also manage it manually.

### 🎯 Quick Test Data Loading
```bash
# Auto-detect environment and load test data
./scripts/quick_start_data.sh

# Or specify environment explicitly
./scripts/quick_start_data.sh --env kubernetes
./scripts/quick_start_data.sh --env docker
```

### 👑 Pre-configured Admin Accounts
**⚠️ IMPORTANT**: For security, use the secure credential generator in production:

```bash
# Generate secure test credentials
python scripts/generate_secure_credentials.py
```

**Development Test Accounts** (change in production):
| Email | Password | Access Level |
|-------|----------|--------------|
| `admin@senecabooks.com` | `[Generated]` | Full admin access |
| `librarian@senecabooks.com` | `[Generated]` | Full admin access |

### 👤 Sample User Accounts
**Development Test Accounts** (change in production):
| Email | Password | Profile |
|-------|----------|---------|
| `john.doe@example.com` | `[Generated]` | Tech enthusiast |
| `jane.smith@example.com` | `[Generated]` | Literature lover |
| `alice.johnson@example.com` | `[Generated]` | Business professional |

### 📚 Sample Catalog (48 Books)
- **💻 Programming & Technology** (18 books): Clean Code, Design Patterns, JavaScript guides...
- **📖 Classic Literature** (18 books): 1984, Harry Potter, Pride and Prejudice...
- **💼 Business & Self-Development** (12 books): Think and Grow Rich, 7 Habits...

### 📦 Sample Order Data (75 Orders)
- Purchase orders and rental transactions
- Realistic order history across all users
- Buy and rent order types with proper pricing

### 🔧 Manual Test Data Management
```bash
# Generate test data only
python3 scripts/generate_test_data.py

# Load existing test data
python3 scripts/load_test_data.py --env kubernetes

# Reset and reload all data
./scripts/quick_start_data.sh
```

### 📖 Complete Documentation
See **[TEST_DATA.MD](TEST_DATA.MD)** for:
- Complete user credentials list
- Detailed book catalog information  
- Order statistics and examples
- API testing scenarios
- Troubleshooting guide

### 4. Explore External Book Integration
- **Browse by Subject**: Click on categories like "Science Fiction" or "History"
- **Search Books**: Use the search bar to find specific titles or authors
- **Import Books** (Admin Only): Import external books to your local catalog with custom pricing
- **Visual Discovery**: Rich interface with book covers and detailed metadata
- **API Documentation**: 
  - User Service: https://senecabooks.local/api/user/docs
  - Catalog Service: https://senecabooks.local/api/catalog/docs (now includes external book endpoints!)
  - Order Service: https://senecabooks.local/api/order/docs
- **Monitoring & Observability**:
  - **Prometheus**: https://senecabooks.local/prometheus
  - **Grafana**: https://senecabooks.local/grafana (admin/admin123)

## 🔍 External Book Discovery (Open Library Integration)

### Powerful Book Discovery Features
- **🌍 Global Book Database**: Access to millions of books from Open Library
- **🔍 Advanced Search**: Search by title, author, ISBN, or keywords
- **📚 Category Browsing**: Browse 20+ popular subject categories
- **🖼️ Rich Visuals**: Book covers and detailed metadata display
- **📥 Smart Import**: One-click import for admins with custom pricing
- **🏷️ Auto-categorization**: Automatic category assignment from book subjects

### External Book API Endpoints
- **GET** `/books/external/search?q={query}` - Search external books
- **GET** `/books/external/subjects` - Get popular subject categories  
- **GET** `/books/external/subject/{subject}` - Browse books by category
- **GET** `/books/external/isbn/{isbn}` - Get book details by ISBN
- **POST** `/books/import` - Import external book to catalog (Admin only)

### Example Usage
```bash
# Search for science fiction books
curl "https://senecabooks.local/api/catalog/books/external/search?q=science%20fiction&limit=10"

# Browse history books
curl "https://senecabooks.local/api/catalog/books/external/subject/history?limit=20"

# Get book by ISBN
curl "https://senecabooks.local/api/catalog/books/external/isbn/9780451526533"
```

## 🧪 Testing & Quality Assurance

### Comprehensive Testing Suite
```bash
# Run all tests
./test.sh

# Run specific test types
./test.sh --unit-only      # Unit tests only
./test.sh --load-only      # Load tests only
./test.sh --integration    # Integration tests only
./test.sh --monitoring     # Test monitoring stack

# Target specific deployment
./test.sh k8s             # Test Kubernetes deployment
./test.sh docker          # Test Docker deployment
```

### Test Coverage
- **📝 Unit Tests**: pytest suite for authentication endpoints
- **⚡ Load Testing**: Concurrent request testing for high-traffic endpoints
- **🔗 Integration Tests**: End-to-end user workflow validation
- **📊 Performance Tests**: Response time and throughput validation
- **🎯 Monitoring Tests**: Prometheus/Grafana health validation

### Load Testing Features
- **Concurrent Users**: Simulate multiple users simultaneously
- **Mixed Workloads**: Test both /books and /orders endpoints
- **Performance Analytics**: Detailed response time statistics
- **Configurable Load**: Adjustable request counts and duration

## 📊 Monitoring & Observability

### Enterprise Monitoring Stack
- **📈 Prometheus Metrics**: 
  - Request/response tracking across all services
  - Custom business metrics (registrations, orders, views)
  - Performance metrics with histogram data
  - Service health and availability monitoring

- **📊 Grafana Dashboards**: 
  - Pre-configured "Seneca Book Store Overview" dashboard
  - Real-time service performance visualization
  - Alert thresholds for critical metrics
  - Business KPI tracking

### Monitoring Access
- **Prometheus**: https://senecabooks.local/prometheus
- **Grafana**: https://senecabooks.local/grafana
  - **Username**: admin
  - **Password**: admin123
- **Service Metrics**: Each service exposes `/metrics` endpoint

### Key Metrics Tracked
- **User Service**: Registrations, logins, authentication attempts
- **Catalog Service**: Book browsing, search queries, book views
- **Order Service**: Order creation, order views, order types (buy/rent)
- **System Metrics**: Request duration, response status codes, error rates

## 🔐 Security Features

### Comprehensive Security Implementation
- **🔒 HTTPS/TLS**: All traffic encrypted with automatic certificate management
- **🛡️ RBAC**: Role-based access control with dedicated service accounts
- **🌐 Network Policies**: Zero-trust network security with default deny-all
- **📝 Audit Logging**: Complete API request logging with user tracking
- **🔑 JWT Authentication**: Secure token-based authentication system
- **🔐 Secrets Management**: Kubernetes secrets for sensitive configuration

### Security Architecture
```
External Traffic → Ingress (TLS) → Network Policies → RBAC → Services
    HTTPS            Certificate      Zero-Trust     Service      API
  Encryption         Management       Network        Accounts   Logging
```

## 🎨 Frontend Features

### User Interface
- **Warm Color Scheme**: Chocolate orange, sienna, and sandy brown tones
- **Modern Typography**: Inter and Playfair Display fonts
- **Responsive Design**: Mobile-first approach with breakpoints
- **Smooth Animations**: Hover effects and loading states

### User Authentication
- **Login/Register Forms** with validation
- **JWT Token Management** with auto-refresh
- **Protected Routes** based on authentication status
- **Admin Role Detection** for dashboard access

### Book Catalog
- **Search & Filter**: Real-time search with genre filtering
- **Sort Options**: By title, author, or price
- **Stock Indicators**: Real-time availability status
- **Buy/Rent Buttons**: Instant order processing

### Admin Dashboard
- **Book Management**: Full CRUD operations with modal forms
- **Order Tracking**: View all user orders and statistics
- **Revenue Analytics**: Total sales and rental tracking
- **Inventory Management**: Stock level monitoring

### Order History
- **Purchase Tracking**: Complete order history
- **Rental Management**: Due dates and return functionality
- **Status Indicators**: Visual status badges
- **Order Analytics**: Personal spending and rental statistics

## 🛠️ Technology Stack

### Backend Services
- **FastAPI 0.104.1**: Modern, fast web framework
- **SQLAlchemy 2.0.23**: SQL toolkit and ORM
- **PyJWT 2.8.0**: JSON Web Token implementation
- **bcrypt 4.1.2**: Password hashing
- **pytest 7.4.3**: Testing framework

### Frontend Application
- **React 18.2.0**: Modern UI library
- **React Router 6.20.1**: Client-side routing
- **Axios 1.6.2**: HTTP client for API calls
- **CSS Variables**: Modern styling with custom properties

### Infrastructure
- **Docker**: Containerization
- **Docker Compose**: Multi-service orchestration
- **Kubernetes**: Production deployment
- **SQLite**: Lightweight database for development

## 📱 API Endpoints

### User Service (Port 8001)
```
POST   /register          # User registration
POST   /login             # User authentication
GET    /me                # Get current user info
GET    /health            # Health check
```

### Catalog Service (Port 8002)
```
GET    /books             # List all books
POST   /books             # Create book (admin only)
PUT    /books/{id}        # Update book (admin only)
DELETE /books/{id}        # Delete book (admin only)
GET    /books/search      # Search books
POST   /books/seed        # Seed sample data
GET    /health            # Health check
```

### Order Service (Port 8003)
```
POST   /orders            # Create new order
GET    /orders            # Get user orders
GET    /orders/admin      # Get all orders (admin)
PUT    /orders/{id}/return # Return rental
GET    /orders/stats      # Order statistics
GET    /health            # Health check
```

## 🔐 Authentication Flow

1. **User Registration/Login** → JWT Token received
2. **Token Storage** → Stored in localStorage
3. **API Requests** → Token included in Authorization header
4. **Protected Routes** → Token validation on each request
5. **Admin Access** → Additional role-based validation

## 📊 Default Test Users

After running `./deploy.sh seed`:

### Admin User
- **Email**: admin@seneca.ca
- **Password**: admin123
- **Access**: Full admin dashboard + user features

### Regular User
- **Email**: user@seneca.ca
- **Password**: user123
- **Access**: Book catalog + order management

## ☸️ Comprehensive Deployment Script

The project includes a single, powerful deployment script that supports multiple deployment modes:

### Deployment Modes
```bash
# Kubernetes only (production)
./deploy.sh --k8s deploy

# Docker Compose only (development)
./deploy.sh --docker deploy  

# Both deployments (testing)
./deploy.sh --both deploy
```

### Management Commands
```bash
# Check deployment status
./deploy.sh status

# View application logs
./deploy.sh --k8s logs user-service
./deploy.sh --docker logs user-service

# Build images only
./deploy.sh build

# Seed initial data
./deploy.sh --docker seed
./deploy.sh --k8s seed

# Clean up deployments
./deploy.sh cleanup
```

### Kubernetes Specific Commands
```bash
# Access Kubernetes dashboard
minikube dashboard

# View all resources
kubectl get all -n seneca-bookstore

# Port forward for direct access
kubectl port-forward service/user-service 8001:8000 -n seneca-bookstore

# Execute commands in pods
kubectl exec -it deployment/user-service -n seneca-bookstore -- bash
```

### Shutdown Options
```bash
# Clean up Docker Compose deployment
./deploy.sh --docker cleanup

# Clean up Kubernetes deployment  
./deploy.sh --k8s cleanup

# Clean up both deployments
./deploy.sh cleanup

# Use dedicated shutdown script for advanced options
./shutdown.sh soft    # Scale down, preserve everything
./shutdown.sh app     # Remove application (keep Minikube)
./shutdown.sh full    # Stop Minikube, preserve data
./shutdown.sh clean   # Remove everything
```

## 🧪 Testing & Development

### Unified Testing Commands
```bash
# Check deployment status across all modes
./deploy.sh status

# View logs from either deployment
./deploy.sh --docker logs user-service
./deploy.sh --k8s logs user-service

# Test deployments
./deploy.sh --docker seed    # Seed Docker Compose data
./deploy.sh --k8s seed       # Seed Kubernetes data
```

### Frontend Testing
```bash
cd frontend-service
npm test
```

## 📈 Performance & Monitoring

- **Health Checks**: All services include `/health` endpoints
- **Error Handling**: Comprehensive error messages and logging
- **Loading States**: User-friendly loading indicators
- **Responsive Design**: Optimized for all screen sizes
- **API Optimization**: Efficient data fetching with proper caching

## 🔧 Development

### Adding New Features
1. **Backend**: Add endpoints to appropriate service
2. **Frontend**: Create/update React components
3. **API Integration**: Update `services/api.js`
4. **Testing**: Add unit tests for new functionality

### Environment Variables
- **JWT_SECRET_KEY**: Secret for JWT token signing
- **DATABASE_URL**: Database connection string
- **CORS_ORIGINS**: Allowed frontend origins

## 📚 Project Structure

```
Seneca Book Store/
├── frontend-service/          # React application
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── services/          # API services
│   │   └── App.js            # Main app component
│   ├── public/               # Static assets
│   └── package.json          # Dependencies
├── user-service/             # Authentication service
├── catalog-service/          # Book management service
├── order-service/            # Order processing service
├── k8s-manifests/           # Kubernetes deployment files
├── deploy.sh               # Comprehensive deployment script
├── shutdown.sh             # Advanced shutdown script
└── README.md               # This file
```

## 🎯 Future Enhancements

- **Payment Integration**: Stripe/PayPal integration
- **Email Notifications**: Order confirmations and reminders
- **Book Reviews**: User rating and review system
- **Recommendation Engine**: AI-powered book suggestions
- **Advanced Analytics**: Sales and user behavior tracking
- **Mobile App**: React Native mobile application

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Support

For support and questions:
- 📧 Email: support@senecabookstore.com
- 📖 Documentation: [Full API Documentation](http://localhost:8001/docs)
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/issues)

---

**Seneca Book Store** - Building the future of book retail with modern microservices architecture! 📚✨
