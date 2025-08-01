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

# Deploy with Docker Compose only
./deploy.sh --docker deploy

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
- **Production (K8s)**: https://senecabooks.local
- **Development**: http://localhost:3000
- **API Documentation**: 
  - User Service: https://senecabooks.local/api/user/docs
  - Catalog Service: https://senecabooks.local/api/catalog/docs
  - Order Service: https://senecabooks.local/api/order/docs

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
