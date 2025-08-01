import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from unittest.mock import patch
from database import Base, get_db
from main import app

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_catalog.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

# Mock admin user for testing
def mock_get_admin_user():
    return {"id": 1, "email": "admin@seneca.ca", "full_name": "Admin User"}

@pytest.fixture
def admin_override():
    """Override admin authentication for testing."""
    from auth import get_admin_user
    app.dependency_overrides[get_admin_user] = mock_get_admin_user
    yield
    app.dependency_overrides.pop(get_admin_user, None)

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "catalog-service"}

def test_get_empty_books():
    response = client.get("/books")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["books"] == []

def test_create_book(admin_override):
    book_data = {
        "title": "Test Book",
        "author": "Test Author",
        "isbn": "978-1234567890",
        "description": "A test book",
        "category": "Testing",
        "price": 29.99,
        "rent_price": 3.99,
        "available": True,
        "stock_quantity": 5,
        "publication_year": 2024,
        "publisher": "Test Publisher"
    }
    
    response = client.post("/books", json=book_data)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Test Book"
    assert data["author"] == "Test Author"
    assert data["price"] == 29.99
    assert data["rent_price"] == 3.99
    assert "id" in data

def test_get_books_after_creation(admin_override):
    # Create a book first
    book_data = {
        "title": "Another Test Book",
        "author": "Another Author",
        "price": 39.99,
        "rent_price": 4.99
    }
    client.post("/books", json=book_data)
    
    # Get books
    response = client.get("/books")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert len(data["books"]) >= 1

def test_get_book_by_id(admin_override):
    # Create a book first
    book_data = {
        "title": "Specific Test Book",
        "author": "Specific Author",
        "price": 19.99,
        "rent_price": 2.99
    }
    create_response = client.post("/books", json=book_data)
    book_id = create_response.json()["id"]
    
    # Get the specific book
    response = client.get(f"/books/{book_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Specific Test Book"
    assert data["id"] == book_id

def test_get_nonexistent_book():
    response = client.get("/books/99999")
    assert response.status_code == 404
    assert "Book not found" in response.json()["detail"]

def test_update_book(admin_override):
    # Create a book first
    book_data = {
        "title": "Update Test Book",
        "author": "Update Author",
        "price": 25.99,
        "rent_price": 3.99
    }
    create_response = client.post("/books", json=book_data)
    book_id = create_response.json()["id"]
    
    # Update the book
    update_data = {
        "title": "Updated Test Book",
        "price": 35.99
    }
    response = client.put(f"/books/{book_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Test Book"
    assert data["price"] == 35.99
    assert data["author"] == "Update Author"  # Should remain unchanged

def test_delete_book(admin_override):
    # Create a book first
    book_data = {
        "title": "Delete Test Book",
        "author": "Delete Author",
        "price": 15.99,
        "rent_price": 1.99
    }
    create_response = client.post("/books", json=book_data)
    book_id = create_response.json()["id"]
    
    # Delete the book
    response = client.delete(f"/books/{book_id}")
    assert response.status_code == 200
    assert "deleted successfully" in response.json()["message"]
    
    # Verify book is deleted
    get_response = client.get(f"/books/{book_id}")
    assert get_response.status_code == 404

def test_search_books(admin_override):
    # Create test books
    books_data = [
        {"title": "Python Programming", "author": "John Doe", "category": "Programming", "price": 49.99, "rent_price": 5.99},
        {"title": "Web Development", "author": "Jane Smith", "category": "Web", "price": 39.99, "rent_price": 4.99},
    ]
    
    for book_data in books_data:
        client.post("/books", json=book_data)
    
    # Test search by title
    response = client.get("/books?search=Python")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert any("Python" in book["title"] for book in data["books"])
    
    # Test filter by category
    response = client.get("/books?category=Programming")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1

def test_get_categories(admin_override):
    # Create a book with a category
    book_data = {
        "title": "Category Test Book",
        "author": "Category Author",
        "category": "TestCategory",
        "price": 20.99,
        "rent_price": 2.99
    }
    client.post("/books", json=book_data)
    
    response = client.get("/categories")
    assert response.status_code == 200
    data = response.json()
    assert "categories" in data
    assert isinstance(data["categories"], list)

def test_create_book_duplicate_isbn(admin_override):
    book_data = {
        "title": "Duplicate ISBN Book",
        "author": "Duplicate Author",
        "isbn": "978-1111111111",
        "price": 30.99,
        "rent_price": 3.99
    }
    
    # Create first book
    response1 = client.post("/books", json=book_data)
    assert response1.status_code == 200
    
    # Try to create book with same ISBN
    response2 = client.post("/books", json=book_data)
    assert response2.status_code == 400
    assert "already exists" in response2.json()["detail"]
