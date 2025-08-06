# 📊 Seneca Book Store - Enhanced Test Data & System Guide

This document provides comprehensive information about the streamlined test data system, application access, sample credentials, API routes, and system capabilities for the Seneca Book Store project.

## 🚀 Streamlined Data Loading System

### 📋 Enhanced Data Loading Features
- **Service Readiness Monitoring**: Automatic health checking before data loading
- **Robust Error Handling**: Retry logic and fallback mechanisms
- **Comprehensive Verification**: Post-loading verification and result tracking
- **Environment Awareness**: Automatic SSL handling for Kubernetes deployment
- **Progress Tracking**: Real-time progress updates and detailed logging

### �️ Data Loading Scripts (Consolidated)
- **Primary Loader**: `scripts/load_test_data.py` - Enhanced comprehensive data loader
- **Backup Generator**: `scripts/generate_test_data.py` - Test data generation
- **Quick Setup**: `scripts/quick_start_data.sh` - Minimal setup script

### 📊 Loading Process
1. **Service Health Check**: Waits up to 5 minutes for all services to be ready
2. **User Creation**: Creates admin and regular users with authentication tokens
3. **Book Catalog**: Loads 168+ books with complete metadata
4. **Order Generation**: Creates realistic orders with proper user-book relationships
5. **Verification**: Validates loading success and saves results to `test_data/loading_results.json`

## 🌐 Application & Monitoring Access

### 🏠 Main Application
- **Frontend**: https://senecabooks.local
- **Status**: ✅ Fully functional with role-based routing and admin fixes applied

### 🔗 API Documentation & Testing
- **User Service**: https://senecabooks.local/api/user/docs
- **Catalog Service**: https://senecabooks.local/api/catalog/docs (includes external book endpoints)
- **Order Service**: https://senecabooks.local/api/order/docs (with enhanced admin endpoints)

## 🎯 Enhanced Navigation & Dashboard System

### 🏠 Role-Based Dashboard Access (Optimized UI)
**Admin Users** (is_admin: true):
- **Login Redirect**: Automatically directed to `/admin` dashboard
- **Navigation**: Clean navbar with "Catalog", "Discover", "My Orders", "Admin Dashboard"
- **Admin Features**: 
  - ✅ Global order management via `/admin/orders` endpoint
  - ✅ Complete user oversight and system administration
  - ✅ Admin-only order statistics and summaries
  - ✅ Access to all user orders across the system
- **Full Access**: Book management, user oversight, comprehensive order analytics

**Regular Users** (is_admin: false):
- **Login Redirect**: Automatically directed to `/catalog` (user dashboard)  
- **Navigation**: Simplified navbar with "Catalog", "Discover", "My Orders"
- **Access**: Book browsing, ordering, personal order management
- **Restricted**: No admin features or system-wide data access

### 📋 Simplified Navigation Structure (UI Improvements Applied)
```
📚 Catalog → Browse local book inventory (168 books)
🔍 Discover → External book search (Open Library API)
📋 My Orders → Personal order history & rental management
⚙️ Admin Dashboard → Admin-only comprehensive management (admin users only)
🚪 Logout → Secure session termination
```

**Note**: Removed overcrowded "Stats" link that caused 503 errors and simplified Dashboard routing for better UX.

## 🎯 System Overview & Applied Fixes

The Seneca Book Store features a streamlined, production-ready system with all major issues resolved:

### ✅ **Recent Improvements Applied**
- **Order Service Enhancement**: Added comprehensive admin endpoints (`/admin/orders`, `/admin/summary`, `/admin/orders/overdue`)
- **Admin Authorization**: Implemented proper `get_admin_user()` dependency with admin privilege verification
- **UI/UX Improvements**: Simplified navbar, removed problematic Stats link, optimized admin dashboard
- **Data Loading Robustness**: Enhanced service health monitoring and retry logic
- **Error Resolution**: Fixed metrics issues, improved error handling, and streamlined deployment

### 🏗️ **Architecture Features**
- **Real-time Health Monitoring**: Service readiness verification before data loading
- **Comprehensive Admin System**: Full order management across all users
- **Book Catalog**: 168 diverse books with realistic metadata (programming, literature, business)
- **Order Processing**: Complete purchase/rental system with admin oversight
- **External Integration**: Open Library API access to millions of additional books
- **Role-Based Security**: Intelligent dashboard routing and permission-based access control

## 👥 Sample User Accounts

### 👑 Admin Users
| Email | Password | Role | Access Level |
|-------|----------|------|--------------|
| `admin@senecabooks.com` | `admin123` | Administrator | ✅ Full system access, Enhanced Admin Dashboard with global order management |

### 👤 Regular Users  
| Email | Password | Profile |
|-------|----------|---------|
| `john.doe@example.com` | `password123` | Tech enthusiast, programming books |
| `jane.smith@example.com` | `password123` | Literature lover, classic novels |
| `testuser@example.com` | `password123` | Test user for functionality validation |
| Plus 47 additional test users with varied profiles and reading preferences |

## 📚 Enhanced Book Catalog

### 💻 Programming & Technology (18 books)
- **Clean Code** by Robert C. Martin - *Essential software development practices*
- **Design Patterns** by Gang of Four - *Fundamental design patterns in software*
- **JavaScript: The Good Parts** by Douglas Crockford - *JavaScript best practices*
- **Python Crash Course** by Eric Matthes - *Learn Python programming*
- **The Pragmatic Programmer** by David Thomas & Andrew Hunt - *Professional development*
- And 13 more technical titles...

### 📖 Classic Literature (18 books)
- **1984** by George Orwell - *Dystopian masterpiece*
- **To Kill a Mockingbird** by Harper Lee - *American classic*
- **Pride and Prejudice** by Jane Austen - *Romantic fiction*
- **The Great Gatsby** by F. Scott Fitzgerald - *Jazz Age novel*
- **Harry Potter and the Sorcerer's Stone** by J.K. Rowling - *Fantasy adventure*
- And 13 more literary classics...

### 💼 Business & Self-Development (12 books)
- **Think and Grow Rich** by Napoleon Hill - *Success principles*
- **The 7 Habits of Highly Effective People** by Stephen Covey - *Personal development*
- **Good to Great** by Jim Collins - *Business transformation*
- **The Lean Startup** by Eric Ries - *Entrepreneurship methodology*
- And 8 more business titles...

## 📦 Sample Order Data

The test dataset includes **75 sample orders** demonstrating:

### Order Types
- **Buy Orders**: Permanent book purchases ($15-$55 range)
- **Rent Orders**: Temporary book rentals ($3-$12 for 7-30 days)

### Order Statistics
- 45 Purchase orders (60%)
- 30 Rental orders (40%)
- Average order value: $28.50
- Order quantities: 1-3 books per order

## 🚀 Data Loading Procedures

### Prerequisites
Ensure all services are running and healthy:
```bash
# Check Kubernetes deployment
kubectl get pods -n seneca-bookstore

# Verify services are responding
curl -s http://senecabooks.local/api/user/health
curl -s http://senecabooks.local/api/catalog/health  
curl -s http://senecabooks.local/api/order/health
```

### Automatic Loading (Recommended)
Test data is automatically loaded during deployment:
```bash
# Deploy the entire project (includes test data loading)
./deploy.sh

# Or manually load test data after deployment
source .venv/bin/activate
python scripts/load_test_data.py --env kubernetes --data test_data/complete_dataset.json
```

### Data Loading Results
The test data loading creates:
- **Users**: 49 user accounts (including 1 admin)
- **Books**: 200 books with full metadata
- **Open Library**: Integration with millions of external books
- **Orders**: Order creation available (may require service debugging)

### Manual Loading (Advanced)
```bash
# Generate fresh test data
python scripts/generate_test_data.py

# Load specific components
python scripts/load_test_data.py --env kubernetes --users-only
python scripts/load_test_data.py --env kubernetes --books-only
```

## 🌐 Access Information

### Application URLs
- **Production**: `http://senecabooks.local`
- **API Documentation**: `http://senecabooks.local/api/docs`

### Dashboard Access
- **Admin Dashboard**: Login with admin@senecabooks.com → Redirected to `/admin`
- **User Dashboard**: Login with regular user → Redirected to `/catalog`

### API Endpoints
- **User Service**: `http://senecabooks.local/api/user`
- **Catalog Service**: `http://senecabooks.local/api/catalog`
- **Order Service**: `http://senecabooks.local/api/order`
- **External Books**: `http://senecabooks.local/api/catalog/books/external/search`

## 🔧 Data Management

### Generated Files
```
test_data/
├── complete_dataset.json      # Full test dataset (50 users, 200 books, 300 orders)
├── users.json                # User accounts only
├── books.json                # Book catalog only
├── orders.json               # Order templates
└── loading_results.json      # Loading operation results
```

### Data Verification
```bash
# Check loaded book count
curl -s "http://senecabooks.local/api/catalog/books?size=1" | jq '.total'

# Test external book search (Open Library)
curl -s "http://senecabooks.local/api/catalog/books/external/search?q=javascript&limit=1" | jq '.total'

# Verify admin login
curl -s -X POST http://senecabooks.local/api/user/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@senecabooks.com", "password": "admin123"}' | jq '.access_token'
```

## 🎮 Usage Scenarios

### Scenario 1: Admin User Experience
1. **Login**: Use `admin@senecabooks.com` / `admin123`
2. **Book Management**: Add, edit, delete books
3. **User Management**: View all users and orders
4. **External Integration**: Browse and import from Open Library
5. **Analytics**: View order statistics and reports

### Scenario 2: Regular User Experience
1. **Registration**: Create new account or use sample credentials
2. **Book Discovery**: Browse catalog, search books, use filters
3. **External Books**: Discover books from Open Library API
4. **Ordering**: Purchase or rent books
5. **Order History**: View past orders and rentals

### Scenario 3: Developer Testing
1. **API Testing**: Use sample data for endpoint testing
2. **Frontend Testing**: Pre-loaded catalog for UI testing
3. **Integration Testing**: Complete user workflows
4. **Performance Testing**: Large dataset for load testing

## 📊 Data Statistics

### Database Counts
- **Users**: 7 total (2 admin, 5 regular)
- **Books**: 48 total across 3 categories
- **Orders**: 75 total (45 purchases, 30 rentals)
- **Categories**: Programming, Literature, Business

### ISBN Format
All books include valid ISBN-13 format:
```
Programming: 978-0-13-235088-X series
Literature: 978-0-06-112008-X series  
Business: 978-0-671-02708-X series
```

### Pricing Structure
- **Programming Books**: $25-$55 (rent: $8-$12)
- **Literature Books**: $15-$30 (rent: $5-$8)
- **Business Books**: $20-$45 (rent: $6-$10)

## 🔐 Security Notes

### Test Credentials
- **All passwords are for testing only**
- **Change admin credentials in production**
- **Use strong passwords for real deployments**

### API Security
- JWT tokens expire after 24 hours
- Admin routes require admin permissions
- User routes require authentication

## 🛠️ Troubleshooting

### Common Issues
1. **Services not responding**: Check Kubernetes pods status
2. **Authentication failed**: Verify admin credentials
3. **Books not loading**: Ensure admin token is valid
4. **Orders not creating**: Check user authentication

### Reset Data
```bash
# Clear all test data and reload
kubectl delete pods -n seneca-bookstore -l app=catalog-service
kubectl delete pods -n seneca-bookstore -l app=user-service
kubectl delete pods -n seneca-bookstore -l app=order-service

# Wait for pods to restart, then reload data
python3 scripts/load_test_data.py --env kubernetes
```

### Logs and Debugging
```bash
# Check service logs
kubectl logs -n seneca-bookstore deployment/catalog-service
kubectl logs -n seneca-bookstore deployment/user-service
kubectl logs -n seneca-bookstore deployment/order-service

# Check data loading logs
tail -f test_data/loading_results.json
```

## 📞 Support

For questions about test data or data loading:

1. **Check Loading Results**: Review `test_data/loading_results.json`
2. **Verify Services**: Ensure all pods are running
3. **Re-run Scripts**: Test data generation and loading are idempotent
4. **Check Documentation**: Refer to service-specific README files

---

*This test data is designed to provide a comprehensive demonstration of the Seneca Book Store platform. All data is fictional and for testing purposes only.*
