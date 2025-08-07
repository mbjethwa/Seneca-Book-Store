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
- **Advanced Stock Management**: Realistic inventory with zero and low stock scenarios
  - ~6 books with **zero stock** (out of stock)
  - ~12 books with **low stock** (1-3 units)
  - ~182 books with **normal stock** (5-50 units)
- **Complete Metadata**: ISBN, descriptions, authors, genres
- **Real-time Updates**: Stock automatically decreases with orders and increases with rental returns

### 📦 Orders (120+ total)
- **Mixed Types**: ~60% purchases, ~40% rentals
- **Realistic Distribution**: Various order statuses and amounts
- **Rental Tracking**: Due dates, overdue alerts, return tracking
- **Revenue Generation**: Totaling $90,000+ in test transactions
- **Stock Integration**: Orders automatically update catalog inventory

## 🎯 Key Features to Test

### 🛒 Shopping Cart System
- **Persistent Cart**: Items saved during user session
- **Session Management**: Cart cleared on logout for security
- **Real-time Updates**: Live cart count and total calculation
- **Checkout Process**: Complete order placement workflow
- **Stock Validation**: Cart prevents ordering more than available stock

### 📊 Admin Dashboard
- **Real-time Statistics**: Books, orders, revenue, active rentals
- **Order Management**: Filter, search, and track all orders
- **Book Management**: Add, edit, delete books with stock tracking
- **Rental Management**: Overdue tracking and due date monitoring
- **Advanced Inventory Management**: Low stock alerts, stock updates, availability tracking

### 🏪 Advanced Inventory Features (NEW)
- **Real-time Stock Updates**: Inventory automatically decreases when orders are placed
- **Rental Stock Management**: Stock is restored when rental books are returned
- **Out-of-Stock Prevention**: Users cannot order books that are out of stock
- **Low Stock Alerts**: Admin dashboard highlights books with low inventory
- **Stock Visibility**: Users can see exact stock quantities for each book
- **Service Integration**: Order service automatically updates catalog service stock levels

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

## 🧪 Testing Advanced Inventory Management

### 🔬 Inventory Test Scenarios

**Test 1: Out-of-Stock Prevention**
1. Navigate to book catalog
2. Look for books with "Out of stock" badges (approximately 6 books)
3. Verify "Add to Cart" buttons are disabled for these books
4. Attempt to order - should be prevented by UI

**Test 2: Low Stock Alerts** 
1. Login as admin (admin@senecabooks.com / admin123)
2. Go to Admin Dashboard → Books section
3. Look for low stock warnings (books with 1-3 stock)
4. Verify stock quantities are displayed accurately

**Test 3: Real-time Stock Updates**
1. Login as regular user (john.doe@example.com / password123)
2. Find a book with low stock (e.g., 2 units)
3. Add 1 to cart and checkout
4. Refresh catalog - stock should decrease to 1
5. Login as admin to verify admin dashboard reflects the change

**Test 4: Rental Stock Restoration**
1. Rent a book that has low stock
2. As admin, verify stock decreased after rental
3. Return the rental from user dashboard
4. Verify stock is restored after return

**Test 5: Cart Stock Validation**
1. Add multiple copies of a low-stock book to cart
2. Verify quantity cannot exceed available stock
3. Attempt checkout - should show error if exceeding stock

### 📊 Expected Inventory Distribution
- **Zero Stock Books**: ~6 books (3 Programming, 2 Fiction, 1 Business)
- **Low Stock Books**: ~12 books (5 Programming, 4 Fiction, 3 Business)  
- **Normal Stock Books**: ~182 books (remaining inventory)

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
