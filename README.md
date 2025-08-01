# Seneca Book Store - Microservices Architecture

A modern microservices-based bookstore application built with FastAPI backend services and React frontend.

## Architecture Overview

```
├── user-service/          # User management service (FastAPI)
├── catalog-service/       # Book catalog service (FastAPI)
├── order-service/         # Order management service (FastAPI)
├── frontend-service/      # React frontend application
└── k8s-manifests/        # Kubernetes deployment manifests
```

## Services

### Backend Services (FastAPI)

#### User Service (Phase 1 - Complete ✅)
- **Authentication & User Management**
- **Endpoints:**
  - `POST /register` - User registration with email/password
  - `POST /login` - User login returning JWT token
  - `GET /me` - Get current user information (requires authentication)
  - `GET /health` - Service health check
- **Features:**
  - Password hashing with bcrypt
  - JWT token authentication (1-hour expiration)
  - SQLite database with SQLAlchemy ORM
  - User registration validation

#### Catalog Service (Phase 2 - Complete ✅)
- **Book Inventory & Catalog Management**
- **Endpoints:**
  - `GET /books` - List books with search/filter/pagination
  - `GET /books/{id}` - Get specific book details
  - `POST /books` - Add new book (admin only)
  - `PUT /books/{id}` - Update book (admin only)
  - `DELETE /books/{id}` - Delete book (admin only)
  - `GET /categories` - Get all book categories
  - `GET /authors` - Get all authors
  - `POST /seed-data` - Create sample data (admin only)
  - `GET /health` - Service health check
- **Features:**
  - Advanced search and filtering (title, author, category, price range)
  - Pagination support
  - Admin-only book management
  - ISBN validation and duplicate prevention
  - Book availability and stock tracking
  - SQLite database with SQLAlchemy ORM

#### Order Service  
- **Order processing and transactions**
- Basic health check endpoints

All backend services:
- Run on port 8000
- Include health check endpoints (`/` and `/health`)
- Built with FastAPI and uvicorn
- Containerized with Docker

### Frontend Service (React)
- Modern React application
- Serves the user interface
- Runs on port 3000 (development) / 80 (production)
- Built with Create React App

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Python 3.11+ (for local development)
- kubectl (for Kubernetes deployment)

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd "Seneca Book Store"
   ```

2. **Run individual services:**

   **Backend Services:**
   ```bash
   # User Service
   cd user-service
   pip install -r requirements.txt
   python main.py

   # Catalog Service  
   cd catalog-service
   pip install -r requirements.txt
   python main.py

   # Order Service
   cd order-service
   pip install -r requirements.txt
   python main.py
   ```

   **Frontend Service:**
   ```bash
   cd frontend-service
   npm install
   npm start
   ```

3. **Using Docker Compose:**
   ```bash
   ./deploy.sh
   ```

### Production Deployment

Run the deployment script:
```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
- Build all Docker images
- Deploy to Kubernetes cluster
- Set up all services with proper networking

## API Endpoints

### User Service (Port 8000/8001)
- `POST /register` - Register new user
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "full_name": "John Doe"
  }
  ```
- `POST /login` - User login (returns JWT token)
  ```json
  {
    "email": "user@example.com", 
    "password": "password123"
  }
  ```
- `GET /me` - Get current user info (requires Bearer token)
- `GET /health` - Service health status

### Catalog Service (Port 8000/8002)
- `GET /books` - List books with optional filters
  - Query parameters: `page`, `size`, `search`, `category`, `author`, `min_price`, `max_price`, `available_only`
- `GET /books/{id}` - Get specific book
- `POST /books` - Create book (admin only)
  ```json
  {
    "title": "Book Title",
    "author": "Author Name",
    "isbn": "978-1234567890",
    "description": "Book description",
    "category": "Programming",
    "price": 49.99,
    "rent_price": 5.99,
    "available": true,
    "stock_quantity": 10,
    "publication_year": 2024,
    "publisher": "Publisher Name"
  }
  ```
- `PUT /books/{id}` - Update book (admin only)
- `DELETE /books/{id}` - Delete book (admin only)
- `GET /categories` - Get all categories
- `GET /authors` - Get all authors
- `POST /seed-data` - Create sample books (admin only)
- `GET /health` - Service health status

### Order Service (Port 8000/8003)
- `GET /` - Health check
- `GET /health` - Service health status

### Frontend Service
- Accessible via LoadBalancer on port 80

## Authentication

The User Service uses JWT (JSON Web Tokens) for authentication:

1. **Register** a new user with `/register`
2. **Login** with `/login` to receive a JWT token
3. **Include token** in Authorization header: `Bearer <token>`
4. **Access protected routes** like `/me`

**Token Configuration:**
- Expires in 1 hour
- Uses HS256 algorithm
- Secret key configurable via environment variable

## Environment Variables

### User Service
```bash
SECRET_KEY=your-super-secret-jwt-key-change-in-production-please
DATABASE_URL=sqlite:///./users.db
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

### Catalog Service
```bash
DATABASE_URL=sqlite:///./catalog.db
USER_SERVICE_URL=http://localhost:8001
ADMIN_EMAILS=admin@seneca.ca,admin@example.com
```

## Admin Access

To access admin-only endpoints in the Catalog Service:

1. **Register as admin** in User Service with an email from `ADMIN_EMAILS`
2. **Login** to get JWT token
3. **Use Bearer token** in Authorization header for admin endpoints

**Default admin emails**: `admin@seneca.ca`, `admin@example.com`

## Development Guide

### Adding New Features

1. **Backend Services:**
   - Add new endpoints to respective `main.py` files
   - Update requirements.txt if new dependencies needed
   - Rebuild Docker images

2. **Frontend:**
   - Add new components in `src/components/`
   - Update routing in `src/App.js`
   - Rebuild for production deployment

### Testing

Each service can be tested independently:

```bash
# Test backend services
curl http://localhost:8000/health

# Test frontend
curl http://localhost:3000
```

## Monitoring

Health check endpoints are available for all services:
- User Service: `http://user-service:8000/health`
- Catalog Service: `http://catalog-service:8000/health`
- Order Service: `http://order-service:8000/health`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
