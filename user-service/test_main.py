import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database import Base, get_db
from main import app

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
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

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "user-service"}

def test_register_user():
    response = client.post(
        "/register",
        json={"email": "test@example.com", "password": "testpassword", "full_name": "Test User"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["full_name"] == "Test User"
    assert "id" in data

def test_register_duplicate_user():
    # First registration
    client.post(
        "/register",
        json={"email": "duplicate@example.com", "password": "testpassword"}
    )
    
    # Second registration with same email
    response = client.post(
        "/register",
        json={"email": "duplicate@example.com", "password": "testpassword"}
    )
    assert response.status_code == 400
    assert "Email already registered" in response.json()["detail"]

def test_login_user():
    # Register user first
    client.post(
        "/register",
        json={"email": "login@example.com", "password": "testpassword"}
    )
    
    # Login
    response = client.post(
        "/login",
        json={"email": "login@example.com", "password": "testpassword"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

def test_login_invalid_credentials():
    response = client.post(
        "/login",
        json={"email": "nonexistent@example.com", "password": "wrongpassword"}
    )
    assert response.status_code == 401
    assert "Incorrect email or password" in response.json()["detail"]

def test_get_user_me():
    # Register and login first
    client.post(
        "/register",
        json={"email": "me@example.com", "password": "testpassword", "full_name": "Me User"}
    )
    
    login_response = client.post(
        "/login",
        json={"email": "me@example.com", "password": "testpassword"}
    )
    token = login_response.json()["access_token"]
    
    # Get user info
    response = client.get(
        "/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "me@example.com"
    assert data["full_name"] == "Me User"

def test_get_user_me_invalid_token():
    response = client.get(
        "/me",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401
