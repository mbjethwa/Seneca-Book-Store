from fastapi import FastAPI, Depends, HTTPException, status, Query, Request
from fastapi.responses import PlainTextResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import uvicorn
from typing import Optional, List
import logging
import time
import requests

# Import our modules
from database import get_db, OrderType, OrderStatus
from auth import get_current_user, get_book_info, get_admin_user
import crud
import schemas
from metrics import PrometheusMetrics

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("order-service")

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app_name="order")

app = FastAPI(
    title="Order Service", 
    version="3.0.0", 
    description="Order processing service for book purchases and rentals"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://senecabooks.local", "https://senecabooks.local", "*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    """Collect metrics for all requests."""
    start_time = metrics.start_request()
    
    response = await call_next(request)
    
    # Calculate processing time
    process_time = time.time() - start_time
    metrics.end_request()
    
    # Record metrics
    endpoint = request.url.path
    metrics.record_request(request.method, endpoint, response.status_code, process_time)
    
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
    return {"status": "healthy", "service": "order-service"}

@app.get("/health")
async def health():
    return {"status": "OK", "service": "order-service"}

@app.get("/metrics")
async def get_metrics():
    """Expose Prometheus metrics."""
    return PlainTextResponse(metrics.generate_metrics())

@app.post("/orders", response_model=schemas.OrderResponse)
async def create_order(
    order: schemas.OrderCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new order (buy or rent a book)."""
    # Record order creation metric (commented out due to metrics issues)
    # metrics.orders_created.labels(order_type=order.order_type.value).inc()
    
    # Get book information from catalog service
    book_info = await get_book_info(order.book_id)
    if not book_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )
    
    # Check if book is available
    if not book_info["available"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Book is not available"
        )
    
    # Check stock quantity
    if book_info["stock_quantity"] < order.quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough stock. Available: {book_info['stock_quantity']}"
        )
    
    # Create the order
    return crud.create_order(
        db=db, 
        order=order, 
        user_id=current_user["id"], 
        book_info=book_info
    )

@app.get("/orders", response_model=schemas.OrderListResponse)
async def get_user_orders(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(20, ge=1, le=100, description="Page size"),
    order_type: Optional[OrderType] = Query(None, description="Filter by order type"),
    status: Optional[OrderStatus] = Query(None, description="Filter by status"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's orders with optional filtering and pagination."""
    skip = (page - 1) * size
    
    orders, total = crud.get_user_orders(
        db=db,
        user_id=current_user["id"],
        skip=skip,
        limit=size,
        order_type=order_type,
        status=status
    )
    
    return schemas.OrderListResponse(
        orders=orders,
        total=total,
        page=page,
        size=size
    )

@app.get("/orders/{order_id}", response_model=schemas.OrderResponse)
async def get_order(
    order_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific order by ID."""
    # Record order view metric (commented out due to metrics issues)
    # metrics.orders_viewed.inc()
    
    order = crud.get_order_by_id(db, order_id=order_id, user_id=current_user["id"])
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    return order

@app.put("/orders/{order_id}/status", response_model=schemas.OrderResponse)
async def update_order_status(
    order_id: int,
    status_update: schemas.OrderStatusUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update order status."""
    order = crud.update_order_status(
        db, 
        order_id=order_id, 
        status_update=status_update, 
        user_id=current_user["id"]
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    return order

@app.post("/orders/{order_id}/return", response_model=schemas.OrderResponse)
async def return_rental(
    order_id: int,
    return_request: schemas.OrderReturnRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Return a rental order."""
    order = crud.return_rental(
        db, 
        order_id=order_id, 
        return_request=return_request, 
        user_id=current_user["id"]
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rental order not found or cannot be returned"
        )
    return order

@app.get("/orders/summary/me", response_model=schemas.OrderSummary)
async def get_my_order_summary(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get order summary for current user."""
    return crud.get_user_order_summary(db, user_id=current_user["id"])

@app.get("/orders/rentals/active", response_model=List[schemas.OrderResponse])
async def get_active_rentals(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's active rental orders."""
    return crud.get_active_rentals(db, user_id=current_user["id"])

@app.get("/orders/rentals/overdue", response_model=List[schemas.OrderResponse])
async def get_overdue_rentals(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's overdue rental orders."""
    return crud.get_overdue_rentals(db, user_id=current_user["id"])

# Admin-only endpoints
@app.get("/admin/orders", response_model=schemas.AdminOrderListResponse)
async def get_all_orders_admin(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(20, ge=1, le=100, description="Page size"),
    order_type: Optional[OrderType] = Query(None, description="Filter by order type"),
    status: Optional[OrderStatus] = Query(None, description="Filter by status"),
    admin_user: dict = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all orders across all users (admin only)."""
    skip = (page - 1) * size
    
    orders, total = crud.get_all_orders(
        db=db,
        skip=skip,
        limit=size,
        order_type=order_type,
        status=status
    )
    
    # Convert to admin response format
    admin_orders = []
    for order in orders:
        order_data = schemas.AdminOrderResponse.model_validate(order)
        # Set a placeholder email - will be enhanced later
        order_data.user_email = f"user_{order.user_id}@senecabooks.local"
        admin_orders.append(order_data)
    
    return schemas.AdminOrderListResponse(
        orders=admin_orders,
        total=total,
        page=page,
        size=size
    )

@app.get("/admin/summary", response_model=schemas.AdminSummary)
async def get_admin_summary(
    admin_user: dict = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get admin summary with global statistics."""
    return crud.get_admin_summary(db)

@app.get("/admin/orders/overdue", response_model=List[schemas.AdminOrderResponse])
async def get_all_overdue_rentals_admin(
    admin_user: dict = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all overdue rental orders (admin only)."""
    orders = crud.get_overdue_rentals(db)
    
    # Convert to admin response format
    admin_orders = []
    for order in orders:
        order_data = schemas.AdminOrderResponse.model_validate(order)
        # Set a placeholder email - will be enhanced later
        order_data.user_email = f"user_{order.user_id}@senecabooks.local"
        admin_orders.append(order_data)
    
    return admin_orders

# Development endpoint to create sample data
@app.post("/seed-orders")
async def seed_sample_orders(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create sample orders for testing."""
    sample_orders = [
        {
            "book_id": 1,
            "order_type": OrderType.BUY,
            "quantity": 1,
            "notes": "Sample purchase order"
        },
        {
            "book_id": 2,
            "order_type": OrderType.RENT,
            "quantity": 1,
            "rental_days": 7,
            "notes": "Sample rental order"
        }
    ]
    
    created_orders = []
    for order_data in sample_orders:
        try:
            # Mock book info for development
            book_info = {
                "id": order_data["book_id"],
                "title": f"Sample Book {order_data['book_id']}",
                "author": "Sample Author",
                "isbn": f"978-{order_data['book_id']:010d}",
                "price": 29.99,
                "rent_price": 3.99,
                "available": True,
                "stock_quantity": 10
            }
            
            order = schemas.OrderCreate(**order_data)
            created_order = crud.create_order(
                db=db,
                order=order,
                user_id=current_user["id"],
                book_info=book_info
            )
            created_orders.append(created_order)
        except Exception as e:
            continue  # Skip if error occurs
    
    return {
        "message": f"Created {len(created_orders)} sample orders",
        "orders": created_orders
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
