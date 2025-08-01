from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from database import Book
import schemas
from typing import List, Optional

def get_book_by_id(db: Session, book_id: int) -> Optional[Book]:
    """Get book by ID."""
    return db.query(Book).filter(Book.id == book_id).first()

def get_book_by_isbn(db: Session, isbn: str) -> Optional[Book]:
    """Get book by ISBN."""
    return db.query(Book).filter(Book.isbn == isbn).first()

def get_books(
    db: Session, 
    skip: int = 0, 
    limit: int = 100,
    search: Optional[str] = None,
    category: Optional[str] = None,
    author: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    available_only: bool = True
) -> tuple[List[Book], int]:
    """Get books with optional filtering and pagination."""
    query = db.query(Book)
    
    # Apply filters
    if available_only:
        query = query.filter(Book.available == True)
    
    if search:
        search_filter = or_(
            Book.title.ilike(f"%{search}%"),
            Book.author.ilike(f"%{search}%"),
            Book.description.ilike(f"%{search}%")
        )
        query = query.filter(search_filter)
    
    if category:
        query = query.filter(Book.category.ilike(f"%{category}%"))
    
    if author:
        query = query.filter(Book.author.ilike(f"%{author}%"))
    
    if min_price is not None:
        query = query.filter(Book.price >= min_price)
    
    if max_price is not None:
        query = query.filter(Book.price <= max_price)
    
    # Get total count before pagination
    total = query.count()
    
    # Apply pagination
    books = query.offset(skip).limit(limit).all()
    
    return books, total

def create_book(db: Session, book: schemas.BookCreate) -> Book:
    """Create a new book."""
    db_book = Book(**book.dict())
    db.add(db_book)
    db.commit()
    db.refresh(db_book)
    return db_book

def update_book(db: Session, book_id: int, book_update: schemas.BookUpdate) -> Optional[Book]:
    """Update an existing book."""
    db_book = db.query(Book).filter(Book.id == book_id).first()
    if not db_book:
        return None
    
    update_data = book_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_book, field, value)
    
    db.commit()
    db.refresh(db_book)
    return db_book

def delete_book(db: Session, book_id: int) -> bool:
    """Delete a book."""
    db_book = db.query(Book).filter(Book.id == book_id).first()
    if not db_book:
        return False
    
    db.delete(db_book)
    db.commit()
    return True

def get_categories(db: Session) -> List[str]:
    """Get all unique categories."""
    categories = db.query(Book.category).filter(Book.category.isnot(None)).distinct().all()
    return [cat[0] for cat in categories if cat[0]]

def get_authors(db: Session) -> List[str]:
    """Get all unique authors."""
    authors = db.query(Book.author).distinct().all()
    return [author[0] for author in authors]
