from fastapi import FastAPI, Depends, HTTPException, status, Query, Request
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session
import uvicorn
from typing import Optional, List
import logging
import time

# Import our modules
from database import get_db
from auth import get_admin_user, get_current_user
import crud
import schemas
from metrics import PrometheusMetrics
from open_library_api import open_library_api

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("catalog-service")

# Initialize Prometheus metrics
metrics = PrometheusMetrics(service_name="catalog")

app = FastAPI(
    title="Catalog Service", 
    version="2.0.0", 
    description="Book catalog and inventory management service"
)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    """Collect metrics for all requests."""
    start_time = time.time()
    
    # Record request
    metrics.requests_total.labels(
        method=request.method,
        endpoint=request.url.path,
        service="catalog"
    ).inc()
    
    response = await call_next(request)
    
    # Record response time
    duration = time.time() - start_time
    metrics.request_duration.labels(
        method=request.method,
        endpoint=request.url.path,
        service="catalog"
    ).observe(duration)
    
    # Record response status
    metrics.responses_total.labels(
        status_code=response.status_code,
        service="catalog"
    ).inc()
    
    return response

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all API requests with method, path, user, and response status."""
    start_time = time.time()
    
    # Extract user info if available
    user_info = "anonymous"
    try:
        if "authorization" in request.headers:
            auth_header = request.headers["authorization"]
            if auth_header.startswith("Bearer "):
                # For catalog service, we'll just note "authenticated" without verifying
                # since the actual verification happens in the auth middleware
                user_info = "authenticated"
    except Exception:
        pass
    
    # Process request
    response = await call_next(request)
    
    # Calculate processing time
    process_time = time.time() - start_time
    
    # Log the request
    logger.info(
        f"Method: {request.method} | "
        f"Path: {request.url.path} | "
        f"User: {user_info} | "
        f"Status: {response.status_code} | "
        f"Time: {process_time:.3f}s"
    )
    
    return response

@app.get("/")
async def health_check():
    return {"status": "healthy", "service": "catalog-service"}

@app.get("/health")
async def health():
    return {"status": "OK", "service": "catalog-service"}

@app.get("/metrics")
async def get_metrics():
    """Expose Prometheus metrics."""
    return PlainTextResponse(metrics.generate_metrics())

# =============================================================================
# EXTERNAL BOOK DATA ENDPOINTS (Open Library API Integration)
# =============================================================================

@app.get("/books/external/search", response_model=schemas.ExternalBookSearchResponse)
async def search_external_books(
    q: str = Query(..., min_length=1, description="Search query for books"),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
):
    """
    Search for books using Open Library API.
    
    This endpoint searches the vast Open Library database for books matching your query.
    Results include cover images, publication info, and metadata that can be imported
    to your local catalog.
    """
    # Record external search metric
    metrics.catalog_search_queries.inc()
    
    try:
        logger.info(f"Searching external books with query: '{q}', limit: {limit}, offset: {offset}")
        result = await open_library_api.search_books(query=q, limit=limit, offset=offset)
        
        return schemas.ExternalBookSearchResponse(
            books=[schemas.ExternalBook(**book) for book in result["books"]],
            total=result["total"],
            offset=result["offset"],
            limit=result["limit"],
            query=q
        )
        
    except Exception as e:
        logger.error(f"Error searching external books: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search external book database"
        )

@app.get("/books/external/subjects", response_model=List[str])
async def get_popular_subjects():
    """
    Get list of popular book subject categories.
    
    Returns a curated list of popular book categories that can be used
    to browse books by subject using the /books/external/subject/{subject} endpoint.
    """
    try:
        subjects = await open_library_api.get_popular_subjects()
        return subjects
    except Exception as e:
        logger.error(f"Error getting popular subjects: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get popular subjects"
        )

@app.get("/books/external/subject/{subject}", response_model=schemas.ExternalBookSearchResponse)
async def get_books_by_subject(
    subject: str = Query(..., description="Subject category (e.g., 'science_fiction', 'history')"),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip")
):
    """
    Get books by subject category from Open Library.
    
    Browse books by popular categories like 'science_fiction', 'history', 'romance', etc.
    Use /books/external/subjects to get a list of available categories.
    """
    # Record external browsing metric
    metrics.books_browsed.inc()
    
    try:
        logger.info(f"Getting books by subject: '{subject}', limit: {limit}, offset: {offset}")
        result = await open_library_api.get_books_by_subject(subject=subject, limit=limit, offset=offset)
        
        return schemas.ExternalBookSearchResponse(
            books=[schemas.ExternalBook(**book) for book in result["books"]],
            total=result["total"],
            offset=result["offset"],
            limit=result["limit"],
            subject=result["subject"]
        )
        
    except Exception as e:
        logger.error(f"Error getting books by subject '{subject}': {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get books for subject '{subject}'"
        )

@app.get("/books/external/isbn/{isbn}", response_model=Optional[schemas.ExternalBook])
async def get_external_book_by_isbn(isbn: str):
    """
    Get book details by ISBN from Open Library.
    
    Lookup detailed information for a specific book using its ISBN.
    Supports both ISBN-10 and ISBN-13 formats.
    """
    try:
        logger.info(f"Getting external book by ISBN: {isbn}")
        result = await open_library_api.get_book_by_isbn(isbn=isbn)
        
        if result:
            return schemas.ExternalBook(**result)
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Book with ISBN '{isbn}' not found"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting external book by ISBN '{isbn}': {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get book details"
        )

@app.post("/books/import", response_model=schemas.BookResponse)
async def import_external_book(
    import_data: schemas.ExternalBookImport,
    current_user: dict = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """
    Import an external book to the local catalog.
    
    Admin-only endpoint to import books from external sources (like Open Library)
    into the local catalog with pricing and inventory information.
    """
    try:
        external_book = import_data.external_book
        
        # Create BookCreate object from external book data
        book_data = schemas.BookCreate(
            title=external_book.title,
            author=external_book.author,
            isbn=external_book.isbn,
            description=external_book.description or f"A book by {external_book.author}",
            category=import_data.category or (external_book.subjects[0] if external_book.subjects else "General"),
            price=import_data.price,
            rent_price=import_data.rent_price,
            available=True,
            stock_quantity=import_data.stock_quantity,
            publication_year=external_book.publication_year,
            publisher=external_book.publisher,
            cover_url=external_book.cover_url,
            source=external_book.source,
            external_key=external_book.key
        )
        
        # Check if book already exists (by ISBN or title+author)
        existing_book = None
        if external_book.isbn:
            existing_book = crud.get_book_by_isbn(db, isbn=external_book.isbn)
        
        if existing_book:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Book with ISBN '{external_book.isbn}' already exists in catalog"
            )
        
        # Create the book in local database
        new_book = crud.create_book(db=db, book=book_data)
        logger.info(f"Successfully imported book: {new_book.title} (ID: {new_book.id})")
        
        return new_book
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error importing external book: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to import book to catalog"
        )

# =============================================================================
# LOCAL CATALOG ENDPOINTS
# =============================================================================

@app.get("/books", response_model=schemas.BookListResponse)
async def get_books(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(20, ge=1, le=100, description="Page size"),
    search: Optional[str] = Query(None, description="Search in title, author, description"),
    category: Optional[str] = Query(None, description="Filter by category"),
    author: Optional[str] = Query(None, description="Filter by author"),
    min_price: Optional[float] = Query(None, ge=0, description="Minimum price"),
    max_price: Optional[float] = Query(None, ge=0, description="Maximum price"),
    available_only: bool = Query(True, description="Show only available books"),
    db: Session = Depends(get_db)
):
    """Get list of books with optional filtering and pagination."""
    # Record book browsing metric
    metrics.books_browsed.inc()
    
    skip = (page - 1) * size
    
    books, total = crud.get_books(
        db=db,
        skip=skip,
        limit=size,
        search=search,
        category=category,
        author=author,
        min_price=min_price,
        max_price=max_price,
        available_only=available_only
    )
    
    return schemas.BookListResponse(
        books=books,
        total=total,
        page=page,
        size=size
    )

@app.get("/books/{book_id}", response_model=schemas.BookResponse)
async def get_book(book_id: int, db: Session = Depends(get_db)):
    """Get a specific book by ID."""
    # Record book view metric
    metrics.books_viewed.inc()
    
    book = crud.get_book_by_id(db, book_id=book_id)
    if book is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )
    return book

@app.post("/books", response_model=schemas.BookResponse)
async def create_book(
    book: schemas.BookCreate,
    db: Session = Depends(get_db),
    admin_user: dict = Depends(get_admin_user)
):
    """Create a new book (admin only)."""
    # Check if book with same ISBN already exists
    if book.isbn and crud.get_book_by_isbn(db, isbn=book.isbn):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Book with this ISBN already exists"
        )
    
    return crud.create_book(db=db, book=book)

@app.put("/books/{book_id}", response_model=schemas.BookResponse)
async def update_book(
    book_id: int,
    book_update: schemas.BookUpdate,
    db: Session = Depends(get_db),
    admin_user: dict = Depends(get_admin_user)
):
    """Update a book (admin only)."""
    book = crud.update_book(db, book_id=book_id, book_update=book_update)
    if book is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )
    return book

@app.delete("/books/{book_id}")
async def delete_book(
    book_id: int,
    db: Session = Depends(get_db),
    admin_user: dict = Depends(get_admin_user)
):
    """Delete a book (admin only)."""
    success = crud.delete_book(db, book_id=book_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )
    return {"message": "Book deleted successfully"}

@app.get("/categories")
async def get_categories(db: Session = Depends(get_db)):
    """Get all available book categories."""
    categories = crud.get_categories(db)
    return {"categories": categories}

@app.get("/authors")
async def get_authors(db: Session = Depends(get_db)):
    """Get all available authors."""
    authors = crud.get_authors(db)
    return {"authors": authors}

# Development endpoint to create sample data
@app.post("/seed-data")
async def seed_sample_data(
    db: Session = Depends(get_db),
    admin_user: dict = Depends(get_admin_user)
):
    """Create sample books for testing (admin only)."""
    sample_books = [
        {
            "title": "Introduction to Python Programming",
            "author": "John Smith",
            "isbn": "978-1234567890",
            "description": "A comprehensive guide to Python programming for beginners",
            "category": "Programming",
            "price": 49.99,
            "rent_price": 5.99,
            "available": True,
            "stock_quantity": 10,
            "publication_year": 2023,
            "publisher": "Tech Books Inc"
        },
        {
            "title": "Advanced Web Development",
            "author": "Jane Doe",
            "isbn": "978-0987654321",
            "description": "Master modern web development with React and Node.js",
            "category": "Web Development",
            "price": 59.99,
            "rent_price": 6.99,
            "available": True,
            "stock_quantity": 5,
            "publication_year": 2024,
            "publisher": "Web Masters"
        },
        {
            "title": "Database Design Fundamentals",
            "author": "Bob Johnson",
            "isbn": "978-1122334455",
            "description": "Learn database design principles and SQL",
            "category": "Database",
            "price": 45.99,
            "rent_price": 4.99,
            "available": True,
            "stock_quantity": 8,
            "publication_year": 2023,
            "publisher": "Data Science Press"
        }
    ]
    
    created_books = []
    for book_data in sample_books:
        # Check if book already exists
        if not crud.get_book_by_isbn(db, isbn=book_data["isbn"]):
            book = schemas.BookCreate(**book_data)
            created_book = crud.create_book(db=db, book=book)
            created_books.append(created_book)
    
    return {
        "message": f"Created {len(created_books)} sample books",
        "books": created_books
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
