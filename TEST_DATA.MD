# 📊 Test Data & Access Guide - Seneca Book Store

Quick reference for accessing the application and understanding the test data system.

## 🚀 Quick Access

### 🌐 Application URLs
- **Main Application**: http://senecabooks.local
- **Admin Dashboard**: http://senecabooks.local/admin  
- **User Dashboard**: http://senecabooks.local/dashboard

### 🔐 Login Credentials

**Admin Account:**
```
Email: admin@senecabooks.com
Password: admin123
Role: Administrator
Features: Full system access, order management, user oversight
```

**Sample User Accounts:**
```
Email: john.doe@example.com
Password: password123

Email: jane.smith@example.com  
Password: password123

Email: alice.johnson@example.com
Password: password123
```

## 📊 Test Data Overview

### 👥 Users (50 total)
- **5 Admin users** with full system access
- **45 Regular users** with standard permissions
- All users have realistic profiles and order history
- Secure password generation used for all accounts

### 📚 Books (200 total)
- **Multiple Categories**: Programming, Fiction, Business, Science, etc.
- **Realistic Pricing**: $15-$75 for purchase, $2-$8 for rentals
- **Stock Management**: Varied stock levels (0-50 per book)
- **Complete Metadata**: ISBN, descriptions, authors, genres

### 📦 Orders (120+ total)
- **Mixed Types**: ~60% purchases, ~40% rentals
- **Realistic Distribution**: Various order statuses and amounts
- **Rental Tracking**: Due dates, overdue alerts, return tracking
- **Revenue Generation**: Totaling $90,000+ in test transactions

## 🎯 Key Features to Test

### 🛒 Shopping Cart System
- **Persistent Cart**: Items saved during user session
- **Session Management**: Cart cleared on logout for security
- **Real-time Updates**: Live cart count and total calculation
- **Checkout Process**: Complete order placement workflow

### 📊 Admin Dashboard
- **Real-time Statistics**: Books, orders, revenue, active rentals
- **Order Management**: Filter, search, and track all orders
- **Book Management**: Add, edit, delete books with stock tracking
- **Rental Management**: Overdue tracking and due date monitoring
- **Inventory Alerts**: Low stock notifications and management

### 👤 User Dashboard  
- **Order History**: View all purchases and rentals
- **Active Rentals**: Track due dates and return status
- **Personal Stats**: Purchase summary and rental activity
- **Account Management**: Profile and preferences

## � API Endpoints

### User Service (Authentication)
- **Health**: http://senecabooks.local/api/user/health
- **Docs**: http://senecabooks.local/api/user/docs
- **Register/Login**: JWT token-based authentication

### Catalog Service (Books)
- **Health**: http://senecabooks.local/api/catalog/health
- **Docs**: http://senecabooks.local/api/catalog/docs
- **Browse Books**: Search, filter, and view book details

### Order Service (Orders & Rentals)
- **Health**: http://senecabooks.local/api/order/health
- **Docs**: http://senecabooks.local/api/order/docs
- **Order Management**: Create, track, and manage orders

## 📈 Monitoring Access

### Prometheus (Metrics)
- **URL**: http://senecabooks.local/prometheus
- **Purpose**: Raw metrics data and alerting rules
- **Key Metrics**: Request rates, error rates, business metrics

### Grafana (Dashboards)  
- **URL**: http://senecabooks.local/grafana
- **Login**: admin / admin123
- **Dashboard**: "Seneca Book Store Overview"
- **Features**: Real-time service monitoring and business insights

## 🛠️ Development Commands

### Quick Deployment
```bash
# Full deployment with test data
./deploy.sh

# Check deployment status
kubectl get all -n seneca-bookstore

# View service logs
kubectl logs -f deployment/user-service -n seneca-bookstore
```

### Data Management
```bash
# Reload test data (if needed)
python scripts/load_test_data.py --env kubernetes

# Check data loading results
cat test_data/loading_results.json

# Reset environment
./shutdown.sh clean && ./deploy.sh
```

### Troubleshooting
```bash
# Test API health
curl http://senecabooks.local/api/user/health
curl http://senecabooks.local/api/catalog/health
curl http://senecabooks.local/api/order/health

# Check ingress
kubectl get ingress -n seneca-bookstore

# Monitor pods
kubectl top pods -n seneca-bookstore
```

## ✨ Feature Highlights

### Enhanced User Experience
- **Smart Shopping Cart**: Persistent state management
- **Responsive Design**: Works on desktop and mobile
- **Real-time Updates**: Live cart counts and notifications
- **Intuitive Navigation**: Role-based menu systems

### Advanced Admin Features
- **Comprehensive Analytics**: Revenue, orders, rental tracking
- **Inventory Management**: Stock alerts and management tools
- **User Management**: View all users and their activity
- **System Monitoring**: Health checks and performance metrics

### Security Features
- **JWT Authentication**: Secure token-based login system
- **Session Validation**: Automatic logout on invalid tokens
- **Role-based Access**: Different permissions for admin vs users
- **Deployment Versioning**: Auto-logout on new deployments

---

**📊 Data Status**: Fully Loaded | **🔐 Security**: Production Ready | **📈 Monitoring**: Active | **🚀 Features**: Complete

### 🔗 API Documentation
- **User Service**: http://senecabooks.local/api/user/docs
- **Catalog Service**: http://senecabooks.local/api/catalog/docs  
- **Order Service**: http://senecabooks.local/api/order/docs

### 📈 Monitoring
- **Prometheus**: http://senecabooks.local/prometheus
- **Grafana**: http://senecabooks.local/grafana (admin/admin123)

## 👥 Test Accounts

### 👑 Admin Account
```
Email: admin@senecabooks.com
Password: admin123
Features: Full system access, user management, order oversight
```

### 👤 Sample Users
```
Email: john.doe@example.com
Password: password123

Email: jane.smith@example.com  
Password: password123

Email: alice.johnson@example.com
Password: password123
```

## 📚 Test Data Overview

### 📊 Data Summary
- **Users**: 50 total (5 admin, 45 regular users)
- **Books**: 200 books across multiple categories
- **Orders**: ~120 orders (60% completed, balanced buy/rent ratio)
- **Stock Management**: Realistic inventory with availability tracking
- **Cart System**: Persistent during sessions, cleared on logout

## 🎯 Key Features

### 🛒 Shopping Cart System
- **Persistent Cart**: Items saved during user session
- **Session Management**: Cart cleared on logout for security
- **Real-time Updates**: Live cart count and item management
- **Checkout Integration**: Seamless order placement

### 📊 Admin Dashboard
- **Real-time Statistics**: Books, orders, revenue, active rentals
- **Order Management**: Comprehensive tracking and analytics
- **Book Management**: Complete CRUD with stock tracking
- **Rental Management**: Overdue tracking and due dates
- **Low Stock Alerts**: Automated inventory notifications

### 🔒 Security Features
- **Auto-logout**: Sessions cleared on new deployments
- **Token Validation**: Automatic session validation
- **Session Tracking**: Deployment version tracking
- **Secure Storage**: Encrypted local storage management

## 🔧 Quick Commands

### 🚀 Deployment
```bash
# Full deployment
./deploy.sh

# Check status
kubectl get all -n seneca-bookstore

# View logs
kubectl logs -f deployment/user-service -n seneca-bookstore
```

### 🐛 Troubleshooting
```bash
# Clean redeployment
./shutdown.sh clean
./deploy.sh

# Check pod status
kubectl get pods -n seneca-bookstore

# Monitor resources
kubectl top pods -n seneca-bookstore
```

## 📋 Common Issues & Solutions

**Issue**: Users still logged in after redeployment  
**Solution**: Enhanced auto-logout system now clears all sessions on deployment

**Issue**: Admin dashboard showing inconsistent data  
**Solution**: Fixed duplicate statistics display and unified data sources

**Issue**: Cart items persisting between user sessions  
**Solution**: Cart now properly cleared on logout and session changes

---

*Last Updated: August 7, 2025*  
*System Version: Production v3.0 with Enhanced Security & Streamlined Dashboard*
