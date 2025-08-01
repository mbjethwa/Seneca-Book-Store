from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

class BookBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=500)
    author: str = Field(..., min_length=1, max_length=200)
    isbn: Optional[str] = Field(None, max_length=20)
    description: Optional[str] = Field(None, max_length=2000)
    category: Optional[str] = Field(None, max_length=100)
    price: float = Field(..., gt=0, description="Purchase price must be greater than 0")
    rent_price: float = Field(..., gt=0, description="Rental price must be greater than 0")
    available: bool = True
    stock_quantity: int = Field(1, ge=0, description="Stock quantity must be 0 or greater")
    publication_year: Optional[int] = Field(None, ge=1000, le=2100)
    publisher: Optional[str] = Field(None, max_length=200)
    cover_url: Optional[str] = Field(None, max_length=500, description="URL to book cover image")
    source: Optional[str] = Field("local", max_length=50, description="Data source (local, open_library, etc.)")
    external_key: Optional[str] = Field(None, max_length=200, description="External API key/identifier")

class BookCreate(BookBase):
    pass

class BookUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    author: Optional[str] = Field(None, min_length=1, max_length=200)
    isbn: Optional[str] = Field(None, max_length=20)
    description: Optional[str] = Field(None, max_length=2000)
    category: Optional[str] = Field(None, max_length=100)
    price: Optional[float] = Field(None, gt=0)
    rent_price: Optional[float] = Field(None, gt=0)
    available: Optional[bool] = None
    stock_quantity: Optional[int] = Field(None, ge=0)
    publication_year: Optional[int] = Field(None, ge=1000, le=2100)
    publisher: Optional[str] = Field(None, max_length=200)
    cover_url: Optional[str] = Field(None, max_length=500)
    source: Optional[str] = Field(None, max_length=50)
    external_key: Optional[str] = Field(None, max_length=200)

class BookResponse(BookBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class BookListResponse(BaseModel):
    books: List[BookResponse]
    total: int
    page: int
    size: int
    
class BookSearchQuery(BaseModel):
    search: Optional[str] = None
    category: Optional[str] = None
    author: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    available_only: bool = True

# External Book Data Schemas (Open Library API)
class ExternalBook(BaseModel):
    """Schema for external book data from Open Library API."""
    title: str
    author: str
    isbn: Optional[str] = None
    cover_url: Optional[str] = None
    publication_year: Optional[int] = None
    publisher: Optional[str] = None
    subjects: Optional[List[str]] = []
    languages: Optional[List[str]] = []
    description: Optional[str] = None
    edition_count: Optional[int] = 1
    key: Optional[str] = None
    source: str = "open_library"

class ExternalBookSearchResponse(BaseModel):
    """Response schema for external book search."""
    books: List[ExternalBook]
    total: int
    offset: int
    limit: int
    query: Optional[str] = None
    subject: Optional[str] = None

class ExternalBookImport(BaseModel):
    """Schema for importing external book to local catalog."""
    external_book: ExternalBook
    price: float = Field(..., gt=0, description="Purchase price for local catalog")
    rent_price: float = Field(..., gt=0, description="Rental price for local catalog")
    stock_quantity: int = Field(1, ge=0, description="Initial stock quantity")
    category: Optional[str] = None  # Override category if needed
