from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import requests
import os
from typing import Optional

# Security
security = HTTPBearer()

# Configuration
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
ADMIN_EMAILS = os.getenv("ADMIN_EMAILS", "admin@seneca.ca,admin@example.com").split(",")

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

async def get_admin_user(current_user: dict = Depends(get_current_user)) -> dict:
    """Verify that current user is an admin."""
    user_email = current_user.get("email", "")
    
    if user_email not in ADMIN_EMAILS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    return current_user

# Optional: For testing without user service
async def get_mock_admin() -> dict:
    """Mock admin user for testing purposes."""
    return {
        "id": 1,
        "email": "admin@seneca.ca",
        "full_name": "Admin User"
    }
