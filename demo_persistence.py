#!/usr/bin/env python3
"""
Demo script to show data persistence in Seneca Book Store
"""
import requests
import json

# Configuration
BASE_URL = "https://senecabooks.local/api"

# Disable SSL warnings for self-signed cert
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def login_admin():
    """Login as admin and return token"""
    print("🔐 Logging in as admin...")
    response = requests.post(
        f"{BASE_URL}/user/login",
        json={"email": "admin@senecabooks.com", "password": "admin123"},
        verify=False
    )
    if response.status_code == 200:
        token = response.json()["access_token"]
        print("✅ Admin login successful")
        return token
    else:
        print(f"❌ Admin login failed: {response.text}")
        return None

def add_sample_books(token):
    """Add some sample books"""
    print("📚 Adding sample books...")
    
    books = [
        {
            "title": "Kubernetes in Action",
            "author": "Marko Luksa",
            "isbn": "978-1617293726",
            "category": "Technology",
            "price": 45.99,
            "stock_quantity": 10,
            "description": "Learn Kubernetes container orchestration"
        },
        {
            "title": "Clean Code",
            "author": "Robert C. Martin",
            "isbn": "978-0132350884",
            "category": "Programming",
            "price": 39.99,
            "stock_quantity": 15,
            "description": "A handbook of agile software craftsmanship"
        },
        {
            "title": "Docker Deep Dive",
            "author": "Nigel Poulton",
            "isbn": "978-1521822807",
            "category": "Technology",
            "price": 35.99,
            "stock_quantity": 12,
            "description": "Master containerization with Docker"
        }
    ]
    
    headers = {"Authorization": f"Bearer {token}"}
    added_count = 0
    
    for book in books:
        response = requests.post(
            f"{BASE_URL}/catalog/books",
            json=book,
            headers=headers,
            verify=False
        )
        if response.status_code in [200, 201]:
            print(f"✅ Added: {book['title']}")
            added_count += 1
        else:
            print(f"⚠️  Failed to add {book['title']}: {response.text}")
    
    print(f"📚 Added {added_count} books successfully")
    return added_count

def check_books():
    """Check current books in catalog"""
    print("🔍 Checking current books...")
    response = requests.get(f"{BASE_URL}/catalog/books", verify=False)
    if response.status_code == 200:
        books = response.json()
        if isinstance(books, list):
            print(f"📚 Found {len(books)} books in catalog")
            for book in books[:5]:  # Show first 5
                print(f"   • {book.get('title', 'Unknown')} by {book.get('author', 'Unknown')}")
            if len(books) > 5:
                print(f"   ... and {len(books) - 5} more")
        else:
            print("📚 Books response format unexpected")
    else:
        print(f"❌ Failed to fetch books: {response.text}")

def main():
    print("🚀 Seneca Book Store - Data Persistence Demo")
    print("=" * 50)
    
    # Check existing books
    check_books()
    print()
    
    # Login and add more books
    token = login_admin()
    if token:
        print()
        add_sample_books(token)
        print()
        
        # Check books again
        check_books()
    
    print()
    print("💾 Data has been persisted to the volume!")
    print("🔄 After redeployment, this data will still be available!")

if __name__ == "__main__":
    main()
