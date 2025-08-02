#!/usr/bin/env python3
"""
Comprehensive Test Data Generator for Seneca Book Store
Generates realistic sample data for users, books, and orders across all services.
"""

import json
import random
import string
from datetime import datetime, timedelta
from typing import List, Dict, Any
import hashlib
import uuid

class TestDataGenerator:
    """Generates comprehensive test data for all Seneca Book Store services."""
    
    def __init__(self):
        self.users = []
        self.books = []
        self.orders = []
        
        # Book categories and subjects
        self.categories = [
            "Programming", "Science Fiction", "Fantasy", "Mystery", "Romance", 
            "History", "Biography", "Business", "Self Help", "Technology",
            "Science", "Mathematics", "Philosophy", "Art", "Psychology",
            "Health", "Travel", "Cooking", "Sports", "Religion"
        ]
        
        # Programming book titles and authors
        self.programming_books = [
            ("Clean Code: A Handbook of Agile Software Craftsmanship", "Robert C. Martin", "0132350884"),
            ("Design Patterns: Elements of Reusable Object-Oriented Software", "Gang of Four", "0201633612"),
            ("The Pragmatic Programmer", "David Thomas, Andrew Hunt", "0201616224"),
            ("Code Complete", "Steve McConnell", "0735619670"),
            ("You Don't Know JS: Up & Going", "Kyle Simpson", "1491924462"),
            ("JavaScript: The Good Parts", "Douglas Crockford", "0596517742"),
            ("Python Crash Course", "Eric Matthes", "1593276036"),
            ("Automate the Boring Stuff with Python", "Al Sweigart", "1593275994"),
            ("Learning Python", "Mark Lutz", "1449355730"),
            ("Effective Java", "Joshua Bloch", "0134685997"),
            ("Java: The Complete Reference", "Herbert Schildt", "1259589331"),
            ("Spring in Action", "Craig Walls", "1617294942"),
            ("React: Up & Running", "Stoyan Stefanov", "1491931825"),
            ("Node.js Design Patterns", "Mario Casciaro", "1785885588"),
            ("Docker Deep Dive", "Nigel Poulton", "1521822808"),
            ("Kubernetes in Action", "Marko Luksa", "1617293725"),
            ("System Design Interview", "Alex Xu", "0996049126"),
            ("Cracking the Coding Interview", "Gayle McDowell", "0984782850"),
            ("Introduction to Algorithms", "Thomas Cormen", "0262033844"),
            ("The Art of Computer Programming", "Donald Knuth", "0201896834")
        ]
        
        # Classic literature and popular books
        self.classic_books = [
            ("To Kill a Mockingbird", "Harper Lee", "0061120081", "Fiction"),
            ("1984", "George Orwell", "0452284234", "Science Fiction"),
            ("Pride and Prejudice", "Jane Austen", "0141439513", "Romance"),
            ("The Great Gatsby", "F. Scott Fitzgerald", "0743273567", "Fiction"),
            ("Harry Potter and the Philosopher's Stone", "J.K. Rowling", "0439708184", "Fantasy"),
            ("The Lord of the Rings", "J.R.R. Tolkien", "0544003411", "Fantasy"),
            ("The Catcher in the Rye", "J.D. Salinger", "0316769487", "Fiction"),
            ("Animal Farm", "George Orwell", "0452284244", "Fiction"),
            ("Brave New World", "Aldous Huxley", "0060850523", "Science Fiction"),
            ("The Hobbit", "J.R.R. Tolkien", "0547928221", "Fantasy"),
            ("Fahrenheit 451", "Ray Bradbury", "1451673310", "Science Fiction"),
            ("Dune", "Frank Herbert", "0441013597", "Science Fiction"),
            ("The Hitchhiker's Guide to the Galaxy", "Douglas Adams", "0345391802", "Science Fiction"),
            ("Foundation", "Isaac Asimov", "0553293354", "Science Fiction"),
            ("Neuromancer", "William Gibson", "0441569595", "Science Fiction"),
            ("The Da Vinci Code", "Dan Brown", "0307474275", "Mystery"),
            ("Gone Girl", "Gillian Flynn", "0307588370", "Mystery"),
            ("The Girl with the Dragon Tattoo", "Stieg Larsson", "0307454541", "Mystery"),
            ("The Silence of the Lambs", "Thomas Harris", "0312924585", "Mystery"),
            ("And Then There Were None", "Agatha Christie", "0062073486", "Mystery")
        ]
        
        # Business and self-help books
        self.business_books = [
            ("Think and Grow Rich", "Napoleon Hill", "1585424331", "Business"),
            ("Rich Dad Poor Dad", "Robert Kiyosaki", "1612680194", "Business"),
            ("The 7 Habits of Highly Effective People", "Stephen Covey", "1451639619", "Self Help"),
            ("How to Win Friends and Influence People", "Dale Carnegie", "0671027034", "Self Help"),
            ("Good to Great", "Jim Collins", "0066620996", "Business"),
            ("The Lean Startup", "Eric Ries", "0307887898", "Business"),
            ("Zero to One", "Peter Thiel", "0804139296", "Business"),
            ("The Hard Thing About Hard Things", "Ben Horowitz", "0062273205", "Business"),
            ("Crossing the Chasm", "Geoffrey Moore", "0060517123", "Business"),
            ("The Innovator's Dilemma", "Clayton Christensen", "0062060244", "Business")
        ]
        
        # Sample user data
        self.sample_users = [
            {
                "email": "admin@senecabooks.com",
                "password": "admin123",
                "full_name": "System Administrator",
                "is_admin": True
            },
            {
                "email": "john.doe@example.com", 
                "password": "password123",
                "full_name": "John Doe",
                "is_admin": False
            },
            {
                "email": "jane.smith@example.com",
                "password": "password123", 
                "full_name": "Jane Smith",
                "is_admin": False
            },
            {
                "email": "alice.johnson@example.com",
                "password": "password123",
                "full_name": "Alice Johnson", 
                "is_admin": False
            },
            {
                "email": "bob.wilson@example.com",
                "password": "password123",
                "full_name": "Bob Wilson",
                "is_admin": False
            },
            {
                "email": "sarah.brown@example.com",
                "password": "password123",
                "full_name": "Sarah Brown",
                "is_admin": False
            },
            {
                "email": "mike.davis@example.com",
                "password": "password123",
                "full_name": "Mike Davis",
                "is_admin": False
            },
            {
                "email": "emma.garcia@example.com",
                "password": "password123",
                "full_name": "Emma Garcia", 
                "is_admin": False
            },
            {
                "email": "chris.martinez@example.com",
                "password": "password123",
                "full_name": "Chris Martinez",
                "is_admin": False
            },
            {
                "email": "lisa.anderson@example.com",
                "password": "password123",
                "full_name": "Lisa Anderson",
                "is_admin": False
            }
        ]
    
    def generate_isbn(self) -> str:
        """Generate a realistic-looking ISBN-13."""
        # Generate 12 digits
        isbn_12 = ''.join([str(random.randint(0, 9)) for _ in range(12)])
        
        # Calculate check digit for ISBN-13
        check_sum = 0
        for i, digit in enumerate(isbn_12):
            if i % 2 == 0:
                check_sum += int(digit)
            else:
                check_sum += int(digit) * 3
        
        check_digit = (10 - (check_sum % 10)) % 10
        return isbn_12 + str(check_digit)
    
    def generate_cover_url(self, isbn: str = None) -> str:
        """Generate a cover URL, preferably from Open Library."""
        if isbn and random.choice([True, False]):
            return f"https://covers.openlibrary.org/b/isbn/{isbn}-M.jpg"
        else:
            # Fallback to placeholder images
            width, height = 300, 400
            return f"https://picsum.photos/{width}/{height}?random={random.randint(1, 1000)}"
    
    def generate_description(self, title: str, author: str, category: str) -> str:
        """Generate a realistic book description."""
        descriptions = {
            "Programming": [
                f"A comprehensive guide to mastering {title.split(':')[0] if ':' in title else title}. Written by renowned expert {author}, this book provides practical examples and best practices.",
                f"Learn the fundamentals and advanced concepts with {title}. {author} presents complex topics in an accessible way with real-world examples.",
                f"An essential resource for developers looking to improve their skills. {title} by {author} covers everything from basics to advanced techniques."
            ],
            "Science Fiction": [
                f"A thrilling journey through space and time. {title} by {author} explores themes of technology, humanity, and the future.",
                f"An epic tale that challenges our understanding of reality. {author} weaves a complex narrative in {title} that will keep you on the edge of your seat.",
                f"A masterpiece of speculative fiction. {title} presents a vision of the future that is both fascinating and thought-provoking."
            ],
            "Fantasy": [
                f"Enter a world of magic and adventure. {title} by {author} creates an immersive fantasy realm filled with memorable characters.",
                f"A epic fantasy tale that spans kingdoms and generations. {author} builds a rich world in {title} with intricate magic systems and compelling lore.",
                f"Journey through enchanted lands in this captivating fantasy novel. {title} offers escapism and wonder for readers of all ages."
            ],
            "Mystery": [
                f"A gripping mystery that will keep you guessing until the end. {author} crafts a complex puzzle in {title} with unexpected twists.",
                f"Solve the case alongside compelling characters in this page-turner. {title} delivers suspense and intrigue from start to finish.",
                f"A masterfully plotted mystery novel. {author} creates an atmosphere of tension and suspicion in {title}."
            ],
            "Business": [
                f"Essential insights for business success. {title} by {author} provides practical strategies and proven methodologies for modern entrepreneurs.",
                f"Transform your approach to business with the wisdom in {title}. {author} shares valuable lessons from years of experience.",
                f"A must-read for anyone serious about business growth. {title} offers actionable advice and real-world case studies."
            ]
        }
        
        category_descriptions = descriptions.get(category, [
            f"A compelling read that explores important themes. {title} by {author} offers insights and entertainment in equal measure.",
            f"An engaging book that will resonate with readers. {author} demonstrates masterful storytelling in {title}.",
            f"A thought-provoking work that stays with you long after reading. {title} showcases {author}'s exceptional writing talent."
        ])
        
        return random.choice(category_descriptions)
    
    def generate_users(self, count: int = 50) -> List[Dict[str, Any]]:
        """Generate test user data."""
        users = []
        
        # Add predefined sample users first
        for user_data in self.sample_users:
            users.append({
                "email": user_data["email"],
                "password": user_data["password"],  # Plain text for reference
                "full_name": user_data["full_name"],
                "is_admin": user_data.get("is_admin", False),
                "created_at": (datetime.utcnow() - timedelta(days=random.randint(1, 365))).isoformat()
            })
        
        # Generate additional random users
        first_names = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", 
                      "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
                      "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa",
                      "Matthew", "Betty", "Anthony", "Helen", "Mark", "Sandra", "Donald", "Donna"]
        
        last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
                     "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
                     "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
                     "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker"]
        
        domains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "email.com", "example.com"]
        
        for i in range(len(self.sample_users), count):
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
            domain = random.choice(domains)
            
            # Create unique email
            email_base = f"{first_name.lower()}.{last_name.lower()}"
            if random.choice([True, False]):
                email_base += str(random.randint(1, 999))
            email = f"{email_base}@{domain}"
            
            users.append({
                "email": email,
                "password": "password123",  # Plain text for reference
                "full_name": f"{first_name} {last_name}",
                "is_admin": random.choice([True, False]) if random.random() < 0.1 else False,  # 10% chance of admin
                "created_at": (datetime.utcnow() - timedelta(days=random.randint(1, 365))).isoformat()
            })
        
        self.users = users
        return users
    
    def generate_books(self, count: int = 200) -> List[Dict[str, Any]]:
        """Generate test book data."""
        books = []
        
        # Add programming books
        for title, author, isbn in self.programming_books:
            books.append({
                "title": title,
                "author": author,
                "isbn": isbn,
                "description": self.generate_description(title, author, "Programming"),
                "category": "Programming",
                "price": round(random.uniform(29.99, 79.99), 2),
                "rent_price": round(random.uniform(2.99, 7.99), 2),
                "available": True,
                "stock_quantity": random.randint(5, 50),
                "publication_year": random.randint(2010, 2024),
                "publisher": random.choice(["O'Reilly Media", "Addison-Wesley", "Manning", "Packt", "Apress", "No Starch Press"]),
                "cover_url": self.generate_cover_url(isbn),
                "source": "local",
                "external_key": None
            })
        
        # Add classic and popular books
        for title, author, isbn, category in self.classic_books:
            books.append({
                "title": title,
                "author": author,
                "isbn": isbn,
                "description": self.generate_description(title, author, category),
                "category": category,
                "price": round(random.uniform(12.99, 24.99), 2),
                "rent_price": round(random.uniform(1.99, 4.99), 2),
                "available": True,
                "stock_quantity": random.randint(10, 100),
                "publication_year": random.randint(1950, 2020),
                "publisher": random.choice(["Penguin Classics", "HarperCollins", "Random House", "Simon & Schuster", "Houghton Mifflin"]),
                "cover_url": self.generate_cover_url(isbn),
                "source": "local",
                "external_key": None
            })
        
        # Add business books
        for title, author, isbn, category in self.business_books:
            books.append({
                "title": title,
                "author": author,
                "isbn": isbn,
                "description": self.generate_description(title, author, category),
                "category": category,
                "price": round(random.uniform(15.99, 29.99), 2),
                "rent_price": round(random.uniform(2.49, 5.99), 2),
                "available": True,
                "stock_quantity": random.randint(8, 40),
                "publication_year": random.randint(1990, 2023),
                "publisher": random.choice(["Harvard Business Review Press", "McGraw-Hill", "Wiley", "Portfolio", "Crown Business"]),
                "cover_url": self.generate_cover_url(isbn),
                "source": "local",
                "external_key": None
            })
        
        # Generate additional random books to reach the target count
        book_title_prefixes = [
            "The Art of", "Introduction to", "Advanced", "Complete Guide to", "Mastering",
            "Understanding", "Essential", "Practical", "Modern", "The Science of",
            "Principles of", "Foundations of", "Exploring", "Discovering", "The Power of"
        ]
        
        subjects = [
            "Machine Learning", "Data Science", "Artificial Intelligence", "Web Development",
            "Mobile Programming", "Game Development", "Cybersecurity", "Cloud Computing",
            "Digital Marketing", "Project Management", "Leadership", "Psychology",
            "Physics", "Chemistry", "Biology", "Mathematics", "History", "Philosophy"
        ]
        
        author_names = [
            "Dr. Alexander Thompson", "Prof. Sarah Johnson", "Michael Rodriguez", 
            "Jennifer Chen", "David Kumar", "Dr. Emily Watson", "Robert Li",
            "Maria Santos", "Dr. James Wilson", "Lisa Zhang", "Kevin O'Connor",
            "Dr. Amanda Foster", "Daniel Kim", "Rebecca Adams", "Dr. Thomas Brown"
        ]
        
        publishers = [
            "Academic Press", "MIT Press", "Cambridge University Press", "Oxford University Press",
            "Springer", "Elsevier", "Wiley", "McGraw-Hill", "Pearson", "Cengage Learning"
        ]
        
        while len(books) < count:
            prefix = random.choice(book_title_prefixes)
            subject = random.choice(subjects)
            title = f"{prefix} {subject}"
            author = random.choice(author_names)
            isbn = self.generate_isbn()
            category = random.choice(self.categories)
            
            books.append({
                "title": title,
                "author": author,
                "isbn": isbn,
                "description": self.generate_description(title, author, category),
                "category": category,
                "price": round(random.uniform(19.99, 89.99), 2),
                "rent_price": round(random.uniform(2.99, 8.99), 2),
                "available": random.choice([True, True, True, False]),  # 75% available
                "stock_quantity": random.randint(0, 50),
                "publication_year": random.randint(2000, 2024),
                "publisher": random.choice(publishers),
                "cover_url": self.generate_cover_url(isbn),
                "source": random.choice(["local", "open_library"]),
                "external_key": f"OL{random.randint(1000000, 9999999)}W" if random.choice([True, False]) else None
            })
        
        self.books = books
        return books
    
    def generate_orders(self, user_count: int = 50, book_count: int = 200, order_count: int = 300) -> List[Dict[str, Any]]:
        """Generate test order data."""
        orders = []
        
        order_types = ["buy", "rent"]
        order_statuses = ["pending", "confirmed", "completed", "cancelled", "returned"]
        
        for i in range(order_count):
            user_id = random.randint(1, min(user_count, len(self.users)))
            book_id = random.randint(1, min(book_count, len(self.books)))
            
            # Get book info for the order
            book = self.books[book_id - 1] if book_id <= len(self.books) else {
                "title": "Sample Book", 
                "author": "Sample Author", 
                "isbn": "1234567890123",
                "price": 19.99,
                "rent_price": 3.99
            }
            
            order_type = random.choice(order_types)
            unit_price = book["price"] if order_type == "buy" else book["rent_price"]
            quantity = random.randint(1, 3)
            
            # For rent orders, calculate rental period
            rental_days = None
            rental_start_date = None
            rental_end_date = None
            rental_returned_date = None
            total_amount = unit_price * quantity
            
            if order_type == "rent":
                rental_days = random.randint(7, 30)  # 1-4 weeks
                start_date = datetime.utcnow() - timedelta(days=random.randint(0, 60))
                rental_start_date = start_date.isoformat()
                rental_end_date = (start_date + timedelta(days=rental_days)).isoformat()
                total_amount = unit_price * quantity * rental_days
                
                # Some rentals might be returned
                if random.choice([True, False, False]):  # 33% returned
                    return_date = start_date + timedelta(days=random.randint(1, rental_days + 5))
                    rental_returned_date = return_date.isoformat()
            
            # Order status based on type and timing
            if order_type == "rent" and rental_returned_date:
                status = "returned"
            else:
                status = random.choice(order_statuses)
                # Weight towards completed for realistic data
                if random.random() < 0.6:
                    status = "completed"
                elif random.random() < 0.8:
                    status = "confirmed"
            
            order_date = datetime.utcnow() - timedelta(days=random.randint(0, 180))
            
            orders.append({
                "user_id": user_id,
                "book_id": book_id,
                "order_type": order_type,
                "status": status,
                "book_title": book["title"],
                "book_author": book["author"],
                "book_isbn": book.get("isbn"),
                "unit_price": unit_price,
                "quantity": quantity,
                "total_amount": round(total_amount, 2),
                "rental_days": rental_days,
                "rental_start_date": rental_start_date,
                "rental_end_date": rental_end_date,
                "rental_returned_date": rental_returned_date,
                "notes": f"Order placed via {'mobile app' if random.choice([True, False]) else 'web interface'}",
                "created_at": order_date.isoformat(),
                "updated_at": (order_date + timedelta(days=random.randint(0, 10))).isoformat()
            })
        
        self.orders = orders
        return orders
    
    def generate_all_data(self, users: int = 50, books: int = 200, orders: int = 300) -> Dict[str, Any]:
        """Generate all test data."""
        print(f"🔄 Generating comprehensive test data...")
        print(f"   👥 Users: {users}")
        print(f"   📚 Books: {books}")
        print(f"   📦 Orders: {orders}")
        
        users_data = self.generate_users(users)
        books_data = self.generate_books(books) 
        orders_data = self.generate_orders(users, books, orders)
        
        return {
            "users": users_data,
            "books": books_data,
            "orders": orders_data,
            "generated_at": datetime.utcnow().isoformat(),
            "stats": {
                "total_users": len(users_data),
                "admin_users": len([u for u in users_data if u.get("is_admin", False)]),
                "total_books": len(books_data),
                "available_books": len([b for b in books_data if b["available"]]),
                "total_orders": len(orders_data),
                "buy_orders": len([o for o in orders_data if o["order_type"] == "buy"]),
                "rent_orders": len([o for o in orders_data if o["order_type"] == "rent"]),
                "completed_orders": len([o for o in orders_data if o["status"] == "completed"])
            }
        }
    
    def save_to_files(self, data: Dict[str, Any], output_dir: str = "test_data"):
        """Save generated data to JSON files."""
        import os
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Save individual datasets
        with open(f"{output_dir}/users.json", "w") as f:
            json.dump(data["users"], f, indent=2)
        
        with open(f"{output_dir}/books.json", "w") as f:
            json.dump(data["books"], f, indent=2)
        
        with open(f"{output_dir}/orders.json", "w") as f:
            json.dump(data["orders"], f, indent=2)
        
        # Save complete dataset
        with open(f"{output_dir}/complete_dataset.json", "w") as f:
            json.dump(data, f, indent=2)
        
        print(f"✅ Test data saved to {output_dir}/ directory")

if __name__ == "__main__":
    generator = TestDataGenerator()
    
    # Generate comprehensive test data
    test_data = generator.generate_all_data(users=50, books=200, orders=300)
    
    # Save to files
    generator.save_to_files(test_data)
    
    # Print summary
    print("\n📊 Generated Test Data Summary:")
    print("=" * 40)
    for key, value in test_data["stats"].items():
        print(f"   {key.replace('_', ' ').title()}: {value}")
    
    print(f"\n📅 Generated at: {test_data['generated_at']}")
    print("\n🎉 Test data generation complete!")
