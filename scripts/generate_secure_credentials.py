#!/usr/bin/env python3
"""
Secure test credentials configuration for Seneca Book Store
Generates secure passwords for test accounts.
"""

import secrets
import string
import json
import os
from pathlib import Path

def generate_secure_password(length=12):
    """Generate a secure random password."""
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(characters) for _ in range(length))

def generate_test_credentials():
    """Generate secure test credentials and save them to a file."""
    credentials = {
        "admin": {
            "email": "admin@senecabooks.com",
            "password": generate_secure_password(16),
            "is_admin": True
        },
        "test_users": []
    }
    
    # Generate credentials for test users
    test_emails = [
        "john.doe@example.com",
        "jane.smith@example.com", 
        "alice.johnson@example.com",
        "bob.wilson@example.com",
        "sarah.brown@example.com"
    ]
    
    for email in test_emails:
        credentials["test_users"].append({
            "email": email,
            "password": generate_secure_password(12),
            "is_admin": False
        })
    
    # Save credentials to a secure file
    credentials_file = Path(__file__).parent / "test_credentials.json"
    
    # Ensure the file is created with restrictive permissions
    with open(credentials_file, 'w') as f:
        json.dump(credentials, f, indent=2)
    
    # Set restrictive permissions (owner read/write only)
    os.chmod(credentials_file, 0o600)
    
    print(f"✅ Secure test credentials generated and saved to: {credentials_file}")
    print("⚠️  IMPORTANT: This file contains sensitive credentials and should not be committed to version control.")
    print(f"📧 Admin email: {credentials['admin']['email']}")
    print(f"🔑 Admin password: {credentials['admin']['password']}")
    
    return credentials

if __name__ == "__main__":
    generate_test_credentials()
