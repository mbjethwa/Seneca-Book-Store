from pydantic import BaseModel, Field, validator
from datetime import datetime, date
from typing import Optional, List
from database import OrderType, OrderStatus

class OrderCreate(BaseModel):
    book_id: int = Field(..., gt=0, description="Book ID must be greater than 0")
    order_type: OrderType = Field(..., description="Order type: 'buy' or 'rent'")
    quantity: int = Field(1, ge=1, le=10, description="Quantity must be between 1 and 10")
    rental_days: Optional[int] = Field(None, ge=1, le=365, description="Rental days (1-365, required for rent orders)")
    notes: Optional[str] = Field(None, max_length=500, description="Optional order notes")

    @validator('rental_days', always=True)
    def validate_rental_days(cls, v, values):
        order_type = values.get('order_type')
        if order_type == OrderType.RENT:
            if v is None or v < 1:
                raise ValueError('Rental days are required and must be at least 1 for rent orders')
        elif order_type == OrderType.BUY and v is not None:
            raise ValueError('Rental days should not be specified for buy orders')
        return v

class OrderResponse(BaseModel):
    id: int
    user_id: int
    book_id: int
    order_type: OrderType
    status: OrderStatus
    
    # Book details
    book_title: str
    book_author: str
    book_isbn: Optional[str]
    
    # Pricing
    unit_price: float
    quantity: int
    total_amount: float
    
    # Rental details
    rental_days: Optional[int]
    rental_start_date: Optional[datetime]
    rental_end_date: Optional[datetime]
    rental_returned_date: Optional[datetime]
    
    # Metadata
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class OrderListResponse(BaseModel):
    orders: List[OrderResponse]
    total: int
    page: int
    size: int

class OrderStatusUpdate(BaseModel):
    status: OrderStatus
    notes: Optional[str] = None

class OrderReturnRequest(BaseModel):
    return_date: Optional[datetime] = None
    notes: Optional[str] = Field(None, max_length=500)

class OrderSummary(BaseModel):
    total_orders: int
    total_purchases: int
    total_rentals: int
    total_amount_spent: float
    active_rentals: int

class AdminOrderResponse(BaseModel):
    """Extended order response with user information for admin views"""
    id: int
    user_id: int
    user_email: Optional[str] = None  # Will be populated via user service
    book_id: int
    order_type: OrderType
    status: OrderStatus
    
    # Book details
    book_title: str
    book_author: str
    book_isbn: Optional[str]
    
    # Pricing - map to expected frontend field names
    unit_price: float
    quantity: int
    total_amount: float
    total_price: Optional[float] = None  # Alias for frontend compatibility
    
    # Rental details
    rental_days: Optional[int]
    rental_start_date: Optional[datetime]
    rental_end_date: Optional[datetime]
    rental_returned_date: Optional[datetime]
    returned_at: Optional[datetime] = None  # Alias for frontend compatibility
    
    # Metadata
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    
    def __init__(self, **data):
        # Map total_amount to total_price for frontend compatibility
        if 'total_amount' in data:
            data['total_price'] = data['total_amount']
        # Map rental_returned_date to returned_at for frontend compatibility
        if 'rental_returned_date' in data:
            data['returned_at'] = data['rental_returned_date']
        super().__init__(**data)
    
    class Config:
        from_attributes = True

class AdminOrderListResponse(BaseModel):
    orders: List[AdminOrderResponse]
    total: int
    page: int
    size: int

class AdminSummary(BaseModel):
    total_orders: int
    total_purchases: int
    total_rentals: int
    total_revenue: float
    active_rentals: int
    overdue_rentals: int

class BookInfo(BaseModel):
    """Book information from catalog service"""
    id: int
    title: str
    author: str
    isbn: Optional[str]
    price: float
    rent_price: float
    available: bool
    stock_quantity: int

class AdminOrderResponse(BaseModel):
    """Admin view of order with user information"""
    id: int
    user_id: int
    user_email: Optional[str] = None  # Will be populated dynamically
    book_id: int
    order_type: OrderType
    status: OrderStatus
    
    # Book details
    book_title: str
    book_author: str
    book_isbn: Optional[str]
    
    # Pricing
    unit_price: float
    quantity: int
    total_amount: float
    
    # Rental details
    rental_days: Optional[int]
    rental_start_date: Optional[datetime]
    rental_end_date: Optional[datetime]
    rental_returned_date: Optional[datetime]
    
    # Metadata
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class AdminOrderListResponse(BaseModel):
    """Admin order list with pagination"""
    orders: List[AdminOrderResponse]
    total: int
    page: int
    size: int

class AdminSummary(BaseModel):
    """Admin summary statistics"""
    total_orders: int
    total_purchases: int
    total_rentals: int
    total_revenue: float
    active_rentals: int
    overdue_rentals: int
