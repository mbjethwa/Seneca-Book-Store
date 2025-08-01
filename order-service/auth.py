from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import requests
import os
from typing import Optional

# Security
security = HTTPBearer()

# Configuration
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
CATALOG_SERVICE_URL = os.getenv("CATALOG_SERVICE_URL", "http://localhost:8002")

async def verify_user_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """Verify user token by calling user service."""
    token = credentials.credentials
    
    try:
        # Call user service to verify token
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{USER_SERVICE_URL}/me", headers=headers, timeout=5)
        
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except requests.RequestException:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="User service unavailable"
        )

async def get_current_user(user_data: dict = Depends(verify_user_token)) -> dict:
    """Get current authenticated user."""
    return user_data

async def get_book_info(book_id: int) -> Optional[dict]:
    """Get book information from catalog service."""
    try:
        response = requests.get(f"{CATALOG_SERVICE_URL}/books/{book_id}", timeout=5)
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            return None
        else:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Catalog service error"
            )
    except requests.RequestException:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Catalog service unavailable"
        )

# Optional: For testing without external services
async def get_mock_user() -> dict:
    """Mock user for testing purposes."""
    return {
        "id": 1,
        "email": "test@example.com",
        "full_name": "Test User"
    }

async def get_mock_book(book_id: int) -> dict:
    """Mock book for testing purposes."""
    return {
        "id": book_id,
        "title": f"Test Book {book_id}",
        "author": "Test Author",
        "isbn": f"978-{book_id:010d}",
        "price": 29.99,
        "rent_price": 3.99,
        "available": True,
        "stock_quantity": 5
    }
