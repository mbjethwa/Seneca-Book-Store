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
- ✅ **Kubernetes Support**: Full K8s deployment manifests for scalable deployment

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ and npm
- Python 3.8+
- Docker and Docker Compose
- Git

### 1. Clone and Setup
```bash
git clone <repository-url>
cd "Seneca Book Store"

# Install frontend dependencies
cd frontend-service
npm install
cd ..
```

### 2. Start All Services
```bash
# Make deploy script executable
chmod +x deploy.sh

# Start all services with Docker Compose
./deploy.sh start

# Or start services individually for development
./deploy.sh dev
```

### 3. Initialize Sample Data
```bash
# Create admin user and sample books
./deploy.sh seed
```

### 4. Access the Application
- **Frontend**: http://localhost:3000
- **User Service**: http://localhost:8001/docs
- **Catalog Service**: http://localhost:8002/docs
- **Order Service**: http://localhost:8003/docs

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

## 🐳 Docker Deployment

### Development Mode
```bash
# Start all services for development
./deploy.sh dev

# View logs
./deploy.sh logs

# Stop all services
./deploy.sh stop
```

### Production Mode
```bash
# Build and start production containers
./deploy.sh start

# Scale services
./deploy.sh scale

# Health check all services
./deploy.sh health
```

## ☸️ Kubernetes Deployment

```bash
# Deploy to Kubernetes
kubectl apply -f k8s-manifests/

# Check deployment status
kubectl get pods

# Access via port forwarding
kubectl port-forward service/frontend-service 3000:3000
```

## 🧪 Testing

### Backend Testing
```bash
# Test all services
./deploy.sh test

# Test specific service
cd user-service && python -m pytest
cd catalog-service && python -m pytest
cd order-service && python -m pytest
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
├── deploy.sh                # Deployment script
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
