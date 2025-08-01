import pytest
import requests
import json
from typing import Dict, Any
import time

# Test configuration
BASE_URL = "http://localhost:8001"  # Docker Compose
K8S_URL = "https://senecabooks.local/api/user"  # Kubernetes

# Use environment-appropriate URL
TEST_URL = BASE_URL

class TestUserService:
    """Comprehensive test suite for User Service endpoints."""
    
    @pytest.fixture(scope="class")
    def test_user_data(self):
        """Test user data for registration and login tests."""
        return {
            "register_data": {
                "email": "test@example.com",
                "password": "testpassword123",
                "is_admin": False
            },
            "admin_data": {
                "email": "admin_test@example.com", 
                "password": "adminpassword123",
                "is_admin": True
            },
            "login_data": {
                "email": "test@example.com",
                "password": "testpassword123"
            },
            "invalid_login": {
                "email": "test@example.com",
                "password": "wrongpassword"
            }
        }
    
    @pytest.fixture(scope="class")
    def cleanup_users(self):
        """Cleanup test users after tests complete."""
        yield
        # Note: In a real scenario, you'd want a cleanup endpoint or direct DB access
        # For now, we'll rely on isolated test environments
    
    def test_health_check(self):
        """Test health check endpoint."""
        response = requests.get(f"{TEST_URL}/health")
        assert response.status_code == 200
        assert response.json()["status"] == "OK"
        assert response.json()["service"] == "user-service"
    
    def test_root_endpoint(self):
        """Test root endpoint health check."""
        response = requests.get(f"{TEST_URL}/")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
        assert response.json()["service"] == "user-service"
    
    def test_register_valid_user(self, test_user_data):
        """Test user registration with valid data."""
        response = requests.post(
            f"{TEST_URL}/register",
            json=test_user_data["register_data"]
        )
        
        assert response.status_code == 200
        response_data = response.json()
        
        assert "id" in response_data
        assert response_data["email"] == test_user_data["register_data"]["email"]
        assert response_data["is_admin"] == test_user_data["register_data"]["is_admin"]
        assert "password" not in response_data  # Password should not be returned
        assert "created_at" in response_data
    
    def test_register_admin_user(self, test_user_data):
        """Test admin user registration."""
        response = requests.post(
            f"{TEST_URL}/register",
            json=test_user_data["admin_data"]
        )
        
        assert response.status_code == 200
        response_data = response.json()
        
        assert response_data["email"] == test_user_data["admin_data"]["email"]
        assert response_data["is_admin"] == True
    
    def test_register_duplicate_email(self, test_user_data):
        """Test registration with duplicate email."""
        # Try to register the same user again
        response = requests.post(
            f"{TEST_URL}/register",
            json=test_user_data["register_data"]
        )
        
        assert response.status_code == 400
        assert "Email already registered" in response.json()["detail"]
    
    def test_register_invalid_email(self):
        """Test registration with invalid email format."""
        invalid_data = {
            "email": "invalid-email",
            "password": "testpassword123",
            "is_admin": False
        }
        
        response = requests.post(f"{TEST_URL}/register", json=invalid_data)
        assert response.status_code == 422  # Validation error
    
    def test_register_missing_fields(self):
        """Test registration with missing required fields."""
        incomplete_data = {
            "email": "incomplete@example.com"
            # Missing password and is_admin
        }
        
        response = requests.post(f"{TEST_URL}/register", json=incomplete_data)
        assert response.status_code == 422  # Validation error
    
    def test_login_valid_credentials(self, test_user_data):
        """Test login with valid credentials."""
        response = requests.post(
            f"{TEST_URL}/login",
            json=test_user_data["login_data"]
        )
        
        assert response.status_code == 200
        response_data = response.json()
        
        assert "access_token" in response_data
        assert "token_type" in response_data
        assert response_data["token_type"] == "bearer"
        assert len(response_data["access_token"]) > 0
    
    def test_login_invalid_credentials(self, test_user_data):
        """Test login with invalid credentials."""
        response = requests.post(
            f"{TEST_URL}/login",
            json=test_user_data["invalid_login"]
        )
        
        assert response.status_code == 401
        assert "Incorrect email or password" in response.json()["detail"]
    
    def test_login_nonexistent_user(self):
        """Test login with non-existent user."""
        nonexistent_data = {
            "email": "nonexistent@example.com",
            "password": "somepassword"
        }
        
        response = requests.post(f"{TEST_URL}/login", json=nonexistent_data)
        assert response.status_code == 401
    
    def test_me_endpoint_with_token(self, test_user_data):
        """Test /me endpoint with valid JWT token."""
        # First login to get token
        login_response = requests.post(
            f"{TEST_URL}/login",
            json=test_user_data["login_data"]
        )
        token = login_response.json()["access_token"]
        
        # Use token to access /me endpoint
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{TEST_URL}/me", headers=headers)
        
        assert response.status_code == 200
        response_data = response.json()
        
        assert response_data["email"] == test_user_data["login_data"]["email"]
        assert "id" in response_data
        assert "created_at" in response_data
    
    def test_me_endpoint_without_token(self):
        """Test /me endpoint without authorization token."""
        response = requests.get(f"{TEST_URL}/me")
        assert response.status_code == 403  # Forbidden
    
    def test_me_endpoint_invalid_token(self):
        """Test /me endpoint with invalid token."""
        headers = {"Authorization": "Bearer invalid_token_here"}
        response = requests.get(f"{TEST_URL}/me", headers=headers)
        assert response.status_code == 401
    
    def test_login_performance(self, test_user_data):
        """Test login endpoint performance."""
        start_time = time.time()
        
        response = requests.post(
            f"{TEST_URL}/login",
            json=test_user_data["login_data"]
        )
        
        end_time = time.time()
        response_time = end_time - start_time
        
        assert response.status_code == 200
        assert response_time < 1.0  # Should respond within 1 second
    
    def test_register_performance(self):
        """Test register endpoint performance."""
        unique_email = f"perf_test_{int(time.time())}@example.com"
        test_data = {
            "email": unique_email,
            "password": "testpassword123",
            "is_admin": False
        }
        
        start_time = time.time()
        
        response = requests.post(f"{TEST_URL}/register", json=test_data)
        
        end_time = time.time()
        response_time = end_time - start_time
        
        assert response.status_code == 200
        assert response_time < 2.0  # Should respond within 2 seconds


class TestUserServiceLoadTesting:
    """Load testing for User Service."""
    
    def test_concurrent_registrations(self):
        """Test multiple concurrent user registrations."""
        import concurrent.futures
        import threading
        
        def register_user(user_id):
            user_data = {
                "email": f"load_test_{user_id}_{int(time.time())}@example.com",
                "password": "loadtestpass123",
                "is_admin": False
            }
            response = requests.post(f"{TEST_URL}/register", json=user_data)
            return response.status_code == 200
        
        # Test with 10 concurrent registrations
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(register_user, i) for i in range(10)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # At least 80% should succeed (allowing for some database contention)
        success_rate = sum(results) / len(results)
        assert success_rate >= 0.8
    
    def test_login_under_load(self, test_user_data):
        """Test login endpoint under load."""
        import concurrent.futures
        
        def perform_login():
            response = requests.post(f"{TEST_URL}/login", json=test_user_data["login_data"])
            return response.status_code == 200
        
        # Test with 20 concurrent logins
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(perform_login) for _ in range(20)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # All logins should succeed
        success_rate = sum(results) / len(results)
        assert success_rate >= 0.95


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
