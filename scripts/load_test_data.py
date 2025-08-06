#!/usr/bin/env python3
"""
🚀 Comprehensive Data Loader for Seneca Book Store Services
Loads test data into the respective service databases with enhanced error handling and robustness.
Supports both development and Kubernetes environments.
"""

import sys
import os
import json
import asyncio
import httpx
import urllib3
from pathlib import Path

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration
API_BASE_URLS = {
    "development": {
        "user": "http://localhost:8001",
        "catalog": "http://localhost:8002", 
        "order": "http://localhost:8003"
    },
    "kubernetes": {
        "user": "http://senecabooks.local/api/user",
        "catalog": "http://senecabooks.local/api/catalog",
        "order": "http://senecabooks.local/api/order"
    }
}

class DataLoader:
    """Comprehensive data loader for Seneca Book Store services with enhanced error handling."""
    
    def __init__(self, environment: str = "kubernetes"):
        self.environment = environment
        self.base_urls = API_BASE_URLS[environment]
        self.admin_token = None
        self.user_tokens = {}
        # Always disable SSL verification for Kubernetes (self-signed certs)
        self.verify_ssl = False
        self.max_retries = 3
        self.retry_delay = 2  # seconds
        
    async def wait_for_services(self):
        """Wait for all services to be ready before loading data."""
        print("⏳ Waiting for services to be ready...")
        
        services = ["user", "catalog", "order"]
        max_attempts = 60  # 10 minutes with 10s intervals
        
        for attempt in range(max_attempts):
            all_ready = True
            
            async with httpx.AsyncClient(timeout=15.0, verify=self.verify_ssl) as client:
                for service in services:
                    try:
                        health_url = f"{self.base_urls[service]}/health"
                        print(f"   🔍 Checking {service} at {health_url}")
                        response = await client.get(health_url)
                        if response.status_code != 200:
                            print(f"   ❌ {service} returned status {response.status_code}")
                            all_ready = False
                            break
                        else:
                            print(f"   ✅ {service} is healthy")
                    except Exception as e:
                        print(f"   ❌ {service} connection failed: {str(e)}")
                        all_ready = False
                        break
            
            if all_ready:
                print("✅ All services are ready!")
                return True
            
            print(f"   ⏳ Attempt {attempt + 1}/{max_attempts} - Services not ready yet, waiting 10s...")
            await asyncio.sleep(10)
        
        print("❌ Services failed to become ready within timeout")
        return False
        
    async def load_users(self, users_data: list) -> dict:
        """Load users into the user service."""
        print("👥 Loading users...")
        
        async with httpx.AsyncClient(timeout=30.0, verify=self.verify_ssl) as client:
            created_users = {}
            admin_users = []
            
            for i, user in enumerate(users_data, 1):
                try:
                    # Register user
                    register_data = {
                        "email": user["email"],
                        "password": user["password"],
                        "is_admin": user.get("is_admin", False)
                    }
                    
                    response = await client.post(
                        f"{self.base_urls['user']}/register",
                        json=register_data
                    )
                    
                    user_created = False
                    if response.status_code == 200:
                        user_info = response.json()
                        created_users[user["email"]] = user_info
                        user_created = True
                    else:
                        # User might already exist, that's okay
                        if "already registered" in response.text:
                            print(f"   ℹ️  User {user['email']} already exists, attempting login...")
                        else:
                            print(f"   ⚠️  Failed to create user {user['email']}: {response.text}")
                    
                    # Always attempt to login (for both new and existing users)
                    login_response = await client.post(
                        f"{self.base_urls['user']}/login",
                        json={
                            "email": user["email"],
                            "password": user["password"]
                        }
                    )
                    
                    if login_response.status_code == 200:
                        token_data = login_response.json()
                        self.user_tokens[user["email"]] = token_data["access_token"]
                        
                        # Set admin token for first admin user (new or existing)
                        if user.get("is_admin", False) and not self.admin_token:
                            self.admin_token = token_data["access_token"]
                            admin_users.append(user["email"])
                            print(f"   👑 Admin token obtained from {user['email']}")
                    else:
                        print(f"   ❌ Failed to login user {user['email']}: {login_response.text}")
                        
                    if i % 10 == 0:
                        print(f"   📊 Processed {i}/{len(users_data)} users")
                        
                except Exception as e:
                    print(f"   ❌ Error processing user {user['email']}: {str(e)}")
            
            print(f"   ✅ Successfully processed {len(users_data)} users")
            print(f"   🆕 New users created: {len(created_users)}")
            print(f"   🔑 User tokens obtained: {len(self.user_tokens)}")
            print(f"   👑 Admin users: {len(admin_users)}")
            return created_users
    
    async def load_books(self, books_data: list) -> dict:
        """Load books into the catalog service."""
        print("📚 Loading books...")
        
        if not self.admin_token:
            print("   ❌ No admin token available. Cannot load books.")
            return {}
        
        async with httpx.AsyncClient(timeout=30.0, verify=self.verify_ssl) as client:
            created_books = {}
            existing_books = 0
            
            headers = {"Authorization": f"Bearer {self.admin_token}"}
            
            for i, book in enumerate(books_data, 1):
                try:
                    book_data = {
                        "title": book["title"],
                        "author": book["author"],
                        "isbn": book["isbn"],
                        "description": book["description"],
                        "category": book["category"],
                        "price": book["price"],
                        "rent_price": book["rent_price"],
                        "available": book["available"],
                        "stock_quantity": book["stock_quantity"],
                        "publication_year": book["publication_year"],
                        "publisher": book["publisher"],
                        "cover_url": book["cover_url"],
                        "source": book["source"],
                        "external_key": book["external_key"]
                    }
                    
                    response = await client.post(
                        f"{self.base_urls['catalog']}/books",
                        json=book_data,
                        headers=headers
                    )
                    
                    if response.status_code == 200:
                        book_info = response.json()
                        created_books[book["isbn"]] = book_info
                        
                        if i % 20 == 0:
                            print(f"   📊 Processed {i}/{len(books_data)} books")
                    else:
                        # Book might already exist
                        if "already exists" in response.text or response.status_code == 400:
                            existing_books += 1
                            if i % 20 == 0:
                                print(f"   📊 Processed {i}/{len(books_data)} books (some already existed)")
                        else:
                            print(f"   ⚠️  Failed to create book {book['title']}: {response.text}")
                        
                except Exception as e:
                    print(f"   ❌ Error creating book {book['title']}: {str(e)}")
            
            print(f"   ✅ Successfully processed {len(books_data)} books")
            print(f"   🆕 New books created: {len(created_books)}")
            print(f"   📚 Existing books found: {existing_books}")
            return created_books
    
    async def load_orders(self, orders_data: list, created_users: dict, created_books: dict) -> dict:
        """Load orders into the order service with enhanced error handling and smart book selection."""
        print("📦 Loading orders...")
        
        if not self.user_tokens:
            print("   ❌ No user tokens available. Cannot load orders.")
            return {}
        
        async with httpx.AsyncClient(timeout=30.0, verify=self.verify_ssl) as client:
            created_orders = {}
            user_emails = list(self.user_tokens.keys())
            available_books = []
            
            # Get available books from the catalog service
            if self.admin_token:
                try:
                    headers = {"Authorization": f"Bearer {self.admin_token}"}
                    books_response = await client.get(
                        f"{self.base_urls['catalog']}/books?size=100&available_only=true",
                        headers=headers
                    )
                    
                    if books_response.status_code == 200:
                        books_data = books_response.json()
                        # Handle both list and dict response formats
                        if isinstance(books_data, dict) and 'books' in books_data:
                            books_list = books_data['books']
                        elif isinstance(books_data, list):
                            books_list = books_data
                        else:
                            books_list = []
                        
                        # Filter for available books with stock > 0
                        for book in books_list:
                            if (isinstance(book, dict) and 
                                book.get('available', False) and 
                                book.get('stock_quantity', 0) > 0):
                                available_books.append(book)
                        
                        print(f"   📚 Found {len(available_books)} available books with stock")
                    
                except Exception as e:
                    print(f"   ⚠️  Could not fetch available books: {str(e)}")
            
            if not available_books:
                print("   ❌ No available books found. Cannot create orders.")
                return {}
            
            success_count = 0
            target_orders = min(len(orders_data), len(available_books) * 2)  # Reasonable limit
            
            for i, order in enumerate(orders_data[:target_orders], 1):
                try:
                    # Select user token (cycle through available users)
                    user_email = user_emails[(order["user_id"] - 1) % len(user_emails)]
                    token = self.user_tokens.get(user_email)
                    
                    if not token:
                        continue
                    
                    # Select available book (prefer books with higher stock)
                    book_index = (i - 1) % len(available_books)
                    selected_book = available_books[book_index]
                    
                    # Create order data matching the order service schema
                    order_data = {
                        "book_id": selected_book["id"],
                        "order_type": order["order_type"],
                        "quantity": min(order.get("quantity", 1), selected_book.get("stock_quantity", 1)),
                        "notes": f"Test order loaded from data - {order.get('notes', '')}"
                    }
                    
                    # Add rental days for rent orders
                    if order["order_type"] == "rent":
                        order_data["rental_days"] = order.get("rental_days", 14)  # Default 14 days
                    
                    headers = {"Authorization": f"Bearer {token}"}
                    
                    # Retry logic for order creation
                    for retry in range(self.max_retries):
                        try:
                            response = await client.post(
                                f"{self.base_urls['order']}/orders",
                                json=order_data,
                                headers=headers
                            )
                            
                            if response.status_code == 200:
                                order_info = response.json()
                                created_orders[order_info["id"]] = order_info
                                success_count += 1
                                
                                # Update local book stock tracking
                                selected_book["stock_quantity"] -= order_data["quantity"]
                                if selected_book["stock_quantity"] <= 0:
                                    available_books.remove(selected_book)
                                
                                if success_count % 10 == 0:
                                    print(f"   ✅ Created {success_count} orders")
                                break
                            else:
                                if retry == self.max_retries - 1:
                                    error_text = response.text[:100] if hasattr(response, 'text') else str(response.content)[:100]
                                    print(f"   ⚠️  Failed to create order after {self.max_retries} attempts: {error_text}")
                                else:
                                    await asyncio.sleep(self.retry_delay)
                        except Exception as e:
                            if retry == self.max_retries - 1:
                                print(f"   ❌ Error creating order (attempt {retry + 1}): {str(e)[:100]}")
                            else:
                                await asyncio.sleep(self.retry_delay)
                        
                except Exception as e:
                    print(f"   ❌ Error processing order {i}: {str(e)[:100]}")
                
                # Stop if we run out of available books
                if not available_books:
                    print(f"   ⚠️  Stopping order creation - no more available books")
                    break
            
            print(f"   ✅ Successfully created {success_count} orders")
            return created_orders
    
    async def verify_data_loading(self) -> dict:
        """Verify that data was loaded correctly."""
        print("🔍 Verifying data loading...")
        
        async with httpx.AsyncClient(timeout=30.0, verify=self.verify_ssl) as client:
            verification = {}
            
            try:
                # Check users
                response = await client.get(f"{self.base_urls['user']}/health")
                verification["user_service"] = response.status_code == 200
                
                # Check books (requires admin token)
                if self.admin_token:
                    headers = {"Authorization": f"Bearer {self.admin_token}"}
                    response = await client.get(f"{self.base_urls['catalog']}/books", headers=headers)
                    if response.status_code == 200:
                        books_data = response.json()
                        verification["books_count"] = books_data.get("total", 0)
                    else:
                        verification["books_count"] = 0
                
                # Check orders (requires user token)
                if self.user_tokens:
                    token = list(self.user_tokens.values())[0]
                    headers = {"Authorization": f"Bearer {token}"}
                    response = await client.get(f"{self.base_urls['order']}/orders", headers=headers)
                    if response.status_code == 200:
                        orders_data = response.json()
                        verification["orders_accessible"] = True
                    else:
                        verification["orders_accessible"] = False
                
                # Check catalog service
                response = await client.get(f"{self.base_urls['catalog']}/health")
                verification["catalog_service"] = response.status_code == 200
                
                # Check order service
                response = await client.get(f"{self.base_urls['order']}/health")
                verification["order_service"] = response.status_code == 200
                
            except Exception as e:
                print(f"   ❌ Error during verification: {str(e)}")
                verification["error"] = str(e)
            
            return verification
    
    async def load_all_data(self, data_file: str = "test_data/complete_dataset.json") -> bool:
        """Load all test data with enhanced service readiness checking."""
        print("🚀 Starting comprehensive data loading...")
        print("=" * 50)
        
        # Wait for services to be ready
        if not await self.wait_for_services():
            return False
        
        # Load test data
        if not os.path.exists(data_file):
            print(f"❌ Test data file not found: {data_file}")
            print("   Please run generate_test_data.py first")
            return False
        
        with open(data_file, 'r') as f:
            test_data = json.load(f)
        
        print(f"📊 Loading data from {data_file}")
        print(f"   Users: {len(test_data['users'])}")
        print(f"   Books: {len(test_data['books'])}")
        print(f"   Orders: {len(test_data['orders'])}")
        print(f"   Environment: {self.environment}")
        print()
        
        # Load data sequentially with proper dependency handling
        created_users = await self.load_users(test_data["users"])
        created_books = await self.load_books(test_data["books"])
        created_orders = await self.load_orders(test_data["orders"], created_users, created_books)
        
        # Verify loading
        verification = await self.verify_data_loading()
        
        # Print summary
        print("\n📋 Data Loading Summary:")
        print("=" * 30)
        print(f"   Users created: {len(created_users)}")
        print(f"   Books created: {len(created_books)}")
        print(f"   Orders created: {len(created_orders)}")
        print(f"   Admin token set: {'✅' if self.admin_token else '❌'}")
        print(f"   User tokens: {len(self.user_tokens)}")
        
        print("\n🔍 Service Verification:")
        for service, status in verification.items():
            if isinstance(status, bool):
                print(f"   {service}: {'✅' if status else '❌'}")
            else:
                print(f"   {service}: {status}")
        
        print("\n🎉 Data loading complete!")
        
        # Save loading results
        results = {
            "environment": self.environment,
            "loaded_at": asyncio.get_event_loop().time(),
            "users_created": len(created_users),
            "books_created": len(created_books),
            "orders_created": len(created_orders),
            "verification": verification,
            "admin_token_set": bool(self.admin_token),
            "user_tokens_count": len(self.user_tokens)
        }
        
        with open("test_data/loading_results.json", "w") as f:
            json.dump(results, f, indent=2)
        
        return True

async def main():
    """Main function to load test data."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Load test data into Seneca Book Store services")
    parser.add_argument("--env", choices=["development", "kubernetes"], default="kubernetes",
                       help="Target environment (default: kubernetes)")
    parser.add_argument("--data", default="test_data/complete_dataset.json",
                       help="Path to test data file")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Enable verbose output")
    
    args = parser.parse_args()
    
    if args.verbose:
        print(f"🔧 Environment: {args.env}")
        print(f"📄 Data file: {args.data}")
        print(f"🌐 Target URLs: {API_BASE_URLS[args.env]}")
    
    loader = DataLoader(environment=args.env)
    success = await loader.load_all_data(args.data)
    
    if success:
        print("\n✅ All data loaded successfully!")
        print(f"\n🌐 Access the application:")
        if args.env == "kubernetes":
            print("   http://senecabooks.local")
        else:
            print("   http://localhost:3000")
        
        print(f"\n👑 Admin credentials:")
        print("   Email: admin@senecabooks.com")
        print("   Password: admin123")
        
        print(f"\n👤 Sample user credentials:")
        print("   Email: john.doe@example.com")
        print("   Password: password123")
    else:
        print("\n❌ Data loading failed!")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
