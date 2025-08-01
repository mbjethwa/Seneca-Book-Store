import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from unittest.mock import patch, AsyncMock
from database import Base, get_db, OrderType, OrderStatus
from main import app

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_orders.db"
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

# Mock user for testing
def mock_get_current_user():
    return {"id": 1, "email": "test@example.com", "full_name": "Test User"}

# Mock book info
async def mock_get_book_info(book_id: int):
    return {
        "id": book_id,
        "title": f"Test Book {book_id}",
        "author": "Test Author",
        "isbn": f"978-{book_id:010d}",
        "price": 29.99,
        "rent_price": 3.99,
        "available": True,
        "stock_quantity": 10
    }

@pytest.fixture
def auth_override():
    """Override authentication for testing."""
    from auth import get_current_user, get_book_info
    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_book_info] = mock_get_book_info
    yield
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_book_info, None)

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "order-service"}

def test_get_empty_orders(auth_override):
    response = client.get("/orders")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["orders"] == []

def test_create_buy_order(auth_override):
    order_data = {
        "book_id": 1,
        "order_type": "buy",
        "quantity": 2,
        "notes": "Test purchase order"
    }
    
    response = client.post("/orders", json=order_data)
    assert response.status_code == 200
    data = response.json()
    assert data["book_id"] == 1
    assert data["order_type"] == "buy"
    assert data["quantity"] == 2
    assert data["total_amount"] == 59.98  # 29.99 * 2
    assert data["rental_days"] is None
    assert "id" in data

def test_create_rent_order(auth_override):
    order_data = {
        "book_id": 2,
        "order_type": "rent",
        "quantity": 1,
        "rental_days": 7,
        "notes": "Test rental order"
    }
    
    response = client.post("/orders", json=order_data)
    assert response.status_code == 200
    data = response.json()
    assert data["book_id"] == 2
    assert data["order_type"] == "rent"
    assert data["quantity"] == 1
    assert data["rental_days"] == 7
    assert data["total_amount"] == 27.93  # 3.99 * 7 * 1
    assert data["rental_start_date"] is not None
    assert data["rental_end_date"] is not None

def test_create_rent_order_without_rental_days(auth_override):
    order_data = {
        "book_id": 3,
        "order_type": "rent",
        "quantity": 1
        # Missing rental_days
    }
    
    response = client.post("/orders", json=order_data)
    assert response.status_code == 422  # Validation error

def test_create_buy_order_with_rental_days(auth_override):
    order_data = {
        "book_id": 4,
        "order_type": "buy",
        "quantity": 1,
        "rental_days": 7  # Should not be specified for buy orders
    }
    
    response = client.post("/orders", json=order_data)
    assert response.status_code == 422  # Validation error

def test_get_orders_after_creation(auth_override):
    # Create a few orders first
    orders_data = [
        {"book_id": 5, "order_type": "buy", "quantity": 1},
        {"book_id": 6, "order_type": "rent", "quantity": 1, "rental_days": 3}
    ]
    
    for order_data in orders_data:
        client.post("/orders", json=order_data)
    
    # Get orders
    response = client.get("/orders")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 2
    assert len(data["orders"]) >= 2

def test_get_order_by_id(auth_override):
    # Create an order first
    order_data = {
        "book_id": 7,
        "order_type": "buy",
        "quantity": 1,
        "notes": "Specific test order"
    }
    create_response = client.post("/orders", json=order_data)
    order_id = create_response.json()["id"]
    
    # Get the specific order
    response = client.get(f"/orders/{order_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["book_id"] == 7
    assert data["id"] == order_id
    assert data["notes"] == "Specific test order"

def test_get_nonexistent_order(auth_override):
    response = client.get("/orders/99999")
    assert response.status_code == 404
    assert "Order not found" in response.json()["detail"]

def test_update_order_status(auth_override):
    # Create an order first
    order_data = {
        "book_id": 8,
        "order_type": "buy",
        "quantity": 1
    }
    create_response = client.post("/orders", json=order_data)
    order_id = create_response.json()["id"]
    
    # Update status
    status_data = {
        "status": "completed",
        "notes": "Order completed successfully"
    }
    response = client.put(f"/orders/{order_id}/status", json=status_data)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"
    assert "completed successfully" in data["notes"]

def test_return_rental(auth_override):
    # Create a rental order first
    order_data = {
        "book_id": 9,
        "order_type": "rent",
        "quantity": 1,
        "rental_days": 5
    }
    create_response = client.post("/orders", json=order_data)
    order_id = create_response.json()["id"]
    
    # Return the rental
    return_data = {
        "notes": "Returned in good condition"
    }
    response = client.post(f"/orders/{order_id}/return", json=return_data)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "returned"
    assert data["rental_returned_date"] is not None

def test_get_order_summary(auth_override):
    # Create some orders first
    orders_data = [
        {"book_id": 10, "order_type": "buy", "quantity": 1},
        {"book_id": 11, "order_type": "rent", "quantity": 1, "rental_days": 7},
        {"book_id": 12, "order_type": "buy", "quantity": 2}
    ]
    
    for order_data in orders_data:
        client.post("/orders", json=order_data)
    
    response = client.get("/orders/summary/me")
    assert response.status_code == 200
    data = response.json()
    assert "total_orders" in data
    assert "total_purchases" in data
    assert "total_rentals" in data
    assert "total_amount_spent" in data
    assert "active_rentals" in data

def test_filter_orders_by_type(auth_override):
    # Create mixed orders
    orders_data = [
        {"book_id": 13, "order_type": "buy", "quantity": 1},
        {"book_id": 14, "order_type": "rent", "quantity": 1, "rental_days": 3}
    ]
    
    for order_data in orders_data:
        client.post("/orders", json=order_data)
    
    # Filter by buy orders
    response = client.get("/orders?order_type=buy")
    assert response.status_code == 200
    data = response.json()
    assert all(order["order_type"] == "buy" for order in data["orders"])
    
    # Filter by rent orders
    response = client.get("/orders?order_type=rent")
    assert response.status_code == 200
    data = response.json()
    assert all(order["order_type"] == "rent" for order in data["orders"])

def test_get_active_rentals(auth_override):
    # Create a rental order
    order_data = {
        "book_id": 15,
        "order_type": "rent",
        "quantity": 1,
        "rental_days": 10
    }
    client.post("/orders", json=order_data)
    
    response = client.get("/orders/rentals/active")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Should have at least one active rental
    active_rentals = [order for order in data if order["status"] in ["confirmed", "completed"]]
    assert len(active_rentals) >= 1
