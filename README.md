# 📚 Seneca Book Store - Modern Microservices Platform

A complete, production-ready microservices application for book store management with modern authentication, comprehensive admin features, and secure deployment.

## 🚀 Quick Start

```bash
# One-command deployment
./deploy.sh

# Access the application
open http://senecabooks.local

# Admin Login
Email: admin@senecabooks.com
Password: admin123
```

## 🏗️ Architecture

**Microservices Stack:**
- **Frontend Service** (React) - Modern UI with shopping cart & admin dashboard
- **User Service** (FastAPI) - JWT authentication & user management  
- **Catalog Service** (FastAPI) - Book catalog & inventory management
- **Order Service** (FastAPI) - Order processing & rental management

**Infrastructure:**
- **Kubernetes** deployment with RBAC & network policies
- **Docker** containerization with multi-stage builds
- **Prometheus + Grafana** monitoring stack
- **Ingress** with TLS and security headers

## ✨ Features

### 🔐 Security & Authentication
- JWT Authentication with secure token generation
- Role-based Access Control (Admin/User permissions)
- RBAC & Network Policies in Kubernetes
- Automatic Session Management with deployment version tracking

### 📊 Admin Dashboard
- Real-time Statistics (books, orders, revenue, active rentals)
- Order Management with comprehensive tracking
- Book Management with complete CRUD operations
- Rental Management with overdue tracking
- Low Stock Alerts with automated notifications

### 🛒 User Experience
- Shopping Cart with persistent session management
- Book Catalog with search and filtering
- External Book Discovery integration
- Personal Dashboard with order history
- Rental Tracking with due dates

### � Monitoring & Observability
- Prometheus metrics collection
- Grafana dashboards with real-time visualization
- Custom business metrics tracking
- Health check endpoints
- Performance monitoring

## 🛠️ Development

### Prerequisites
- **Docker** & **Docker Compose**
- **Kubernetes** (Minikube for local development)
- **kubectl** configured
- **Python 3.11+** (for local development)
- **Node.js 18+** (for frontend development)

### Project Structure
```
├── frontend-service/     # React.js frontend
├── user-service/        # FastAPI authentication service
├── catalog-service/     # FastAPI book catalog service
├── order-service/       # FastAPI order management service
├── k8s-manifests/       # Kubernetes deployment files
├── scripts/             # Utility scripts
├── test_data/           # Sample data for testing
├── deploy.sh            # Unified deployment script
└── README.md            # This file
```

### Local Development
```bash
# Start all services locally
docker-compose up

# Run individual service
cd user-service && python -m uvicorn main:app --reload

# Run tests
pytest
```

### Production Deployment
```bash
# Deploy to Kubernetes
./deploy.sh --k8s

# Check status
./deploy.sh status

# Clean deployment
./shutdown.sh clean
```

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:
- **SECRET_KEY**: JWT secret (auto-generated if not set)
- **DATABASE_URL**: Database connection string
- **ENVIRONMENT**: deployment environment (dev/prod)

### Security Configuration
- All secrets managed via Kubernetes Secrets
- TLS/HTTPS enforced in production
- Network policies with zero-trust model
- RBAC with least-privilege access

## 📊 Monitoring

**Access Monitoring:**
- **Prometheus**: http://senecabooks.local/prometheus
- **Grafana**: http://senecabooks.local/grafana (admin/admin123)

**Key Metrics:**
- Request rates and response times
- Error rates and service health
- Business metrics (orders, registrations, etc.)
- Resource utilization

## 🧪 Testing

**Included Test Data:**
- 50 test users (5 admin, 45 regular)
- 200 books across multiple categories
- 120+ realistic orders and rentals

**Test Coverage:**
- Unit tests for all services
- Integration tests for API endpoints
- Load testing for performance validation
- Security testing for vulnerability assessment

## 🔍 Troubleshooting

**Common Issues:**
```bash
# Check service health
kubectl get pods -n seneca-bookstore

# View service logs
kubectl logs -f deployment/user-service -n seneca-bookstore

# Test API endpoints
curl http://senecabooks.local/api/user/health
```

**Reset Environment:**
```bash
./shutdown.sh clean
./deploy.sh
```

## � Documentation

- **[Deployment Guide](DEPLOYMENT.md)** - Detailed deployment instructions
- **[Security Policy](SECURITY.md)** - Security features and best practices
- **[Test Data Guide](TEST_DATA.MD)** - Sample data and access information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `pytest`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**🎯 Production Ready** | **🔒 Security Hardened** | **📈 Enterprise Monitoring** | **🚀 Kubernetes Native**
- **Book Discovery** - internal catalog + external book search integration
- **Order History** - purchase and rental tracking with due dates
- **Responsive Design** - works perfectly on all devices
- **Auto-logout Security** - session cleared on new deployments

### 📈 Monitoring & Observability
- **Prometheus Metrics** - request tracking, business metrics, performance data
- **Grafana Dashboards** - pre-configured monitoring with alerts
- **Health Checks** - comprehensive service monitoring
- **Audit Logging** - complete activity tracking

## 📋 System Requirements

- **Docker** & **Docker Compose**
- **Kubernetes** (Minikube for local development)
- **kubectl** configured for your cluster

## 🔧 Deployment

### Local Development (Kubernetes)
```bash
# Deploy everything
./deploy.sh

# Check status
./deploy.sh status

# Clean shutdown
./shutdown.sh
```

### Docker Compose (Alternative)
```bash
# Start all services
docker-compose up -d

# Stop all services  
docker-compose down
```

## 🌐 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Main App** | http://senecabooks.local | Complete book store interface |
| **Admin Dashboard** | http://senecabooks.local/admin | Admin management interface |
| **User API** | http://senecabooks.local/api/user/docs | Authentication API docs |
| **Catalog API** | http://senecabooks.local/api/catalog/docs | Book management API docs |
| **Order API** | http://senecabooks.local/api/order/docs | Order processing API docs |
| **Prometheus** | http://senecabooks.local/prometheus | Metrics monitoring |
| **Grafana** | http://senecabooks.local/grafana | Analytics dashboards |

## 👤 Test Accounts

### Admin Account
- **Email:** admin@senecabooks.com
- **Password:** admin123
- **Access:** Full system administration

### Sample User Account  
- **Email:** john.doe@example.com
- **Password:** password123
- **Access:** Standard user features

## 🛠️ Development

### Running Tests
```bash
# Run all tests
./test.sh

# Individual service tests
cd user-service && python -m pytest
cd catalog-service && python -m pytest  
cd order-service && python -m pytest
```

### Monitoring
```bash
# Check all pods
kubectl get pods -n seneca-bookstore

# View service logs
kubectl logs -f deployment/user-service -n seneca-bookstore

# Monitor resource usage
kubectl top pods -n seneca-bookstore
```

## 🔒 Security Features

- **JWT Authentication** with secure token generation
- **RBAC** in Kubernetes with least-privilege access
- **Network Policies** for zero-trust architecture  
- **Session Management** with automatic logout on deployments
- **Comprehensive Audit Logging** for all actions
- **Security Headers** and HTTPS everywhere

## 📊 Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | React, Nginx | Modern responsive UI |
| **Backend** | FastAPI, Python | Microservices APIs |
| **Database** | SQLite, SQLAlchemy | Data persistence |  
| **Authentication** | JWT, bcrypt | Secure user auth |
| **Orchestration** | Kubernetes, Docker | Container management |
| **Monitoring** | Prometheus, Grafana | Observability stack |
| **Networking** | Ingress, NetworkPolicies | Secure routing |

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT.md)** - Detailed deployment instructions
- **[Security Policy](SECURITY.md)** - Security features and comprehensive audit results
- **[Test Data Guide](TEST_DATA.MD)** - Sample data and access information
- **[API Documentation](http://senecabooks.local/api/docs)** - Interactive API docs

## 🎯 Project Status

✅ **Production Ready** - Complete microservices platform  
✅ **Security Audited** - Comprehensive security review passed  
✅ **Fully Tested** - Unit, integration, and load tests  
✅ **Monitored** - Full observability with Prometheus + Grafana  
✅ **Documented** - Complete documentation and guides

---

**Built with ❤️ for Seneca College**  
*Modern microservices architecture demonstrating enterprise development practices*
  ---

**Built with ❤️ for Seneca College**  
*Modern microservices architecture demonstrating enterprise development practices*

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
