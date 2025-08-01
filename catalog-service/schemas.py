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
