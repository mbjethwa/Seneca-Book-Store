# 📊 Seneca Book Store - Test Data Documentation

This document provides comprehensive information about the test datasets, sample credentials, and data loading procedures for the Seneca Book Store project.

## 🎯 Overview

The Seneca Book Store comes with pre-configured test data to demonstrate all features and functionality. This includes:

- **Sample Users**: Admin and regular user accounts with predefined credentials
- **Book Catalog**: Programming, classic literature, and business books with realistic metadata
- **Order History**: Sample purchase and rental transactions
- **External Integration**: Mock data for Open Library API integration

## 👥 Sample User Accounts

### 👑 Admin Users
| Email | Password | Role | Access Level |
|-------|----------|------|--------------|
| `admin@senecabooks.com` | `admin123` | Administrator | Full system access |
| `librarian@senecabooks.com` | `librarian456` | Administrator | Full system access |

### 👤 Regular Users
| Email | Password | Profile |
|-------|----------|---------|
| `john.doe@example.com` | `password123` | Tech enthusiast, programming books |
| `jane.smith@example.com` | `password456` | Literature lover, classic novels |
| `alice.johnson@example.com` | `password789` | Business professional |
| `bob.wilson@example.com` | `password321` | Academic researcher |
| `carol.brown@example.com` | `password654` | Fiction reader |

## 📚 Sample Book Catalog

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

## 🚀 Data Loading Instructions

### Prerequisites
```bash
# Ensure all services are running
kubectl get pods -n seneca-bookstore

# Or for development environment
docker-compose up -d
```

### Method 1: Automatic Loading (Recommended)
```bash
# Navigate to the project root
cd "/home/mj/Seneca Book Store"

# Generate test data
python3 scripts/generate_test_data.py

# Load data into Kubernetes environment
python3 scripts/load_test_data.py --env kubernetes

# Or load into development environment
python3 scripts/load_test_data.py --env development
```

### Method 2: Manual Service-by-Service Loading
```bash
# Load users first
curl -X POST https://senecabooks.local/api/user/register \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@senecabooks.com", "password": "admin123", "is_admin": true}'

# Login to get admin token
ADMIN_TOKEN=$(curl -X POST https://senecabooks.local/api/user/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@senecabooks.com", "password": "admin123"}' | jq -r '.access_token')

# Load books using admin token
curl -X POST https://senecabooks.local/api/catalog/books \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @test_data/sample_book.json
```

## 🌐 Access Information

### Application URLs
- **Production**: `https://senecabooks.local`
- **Development**: `http://localhost:3000`

### API Endpoints
- **User Service**: `https://senecabooks.local/api/user`
- **Catalog Service**: `https://senecabooks.local/api/catalog`
- **Order Service**: `https://senecabooks.local/api/order`

### Service Documentation
- **API Docs**: `https://senecabooks.local/api/docs`
- **OpenAPI Schema**: `https://senecabooks.local/api/openapi.json`

## 🔧 Data Management

### Generated Files
```
test_data/
├── complete_dataset.json      # Full test dataset
├── users_only.json           # User accounts only
├── books_only.json           # Book catalog only
├── orders_only.json          # Order history only
└── loading_results.json      # Loading operation results
```

### Data Verification
```bash
# Check data loading results
cat test_data/loading_results.json

# Verify user count
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  https://senecabooks.local/api/user/users | jq '.total'

# Verify book count
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  https://senecabooks.local/api/catalog/books | jq '.total'
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
