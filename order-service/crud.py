from sqlalchemy.orm import Session
from sqlalchemy import and_, desc
from database import Order, OrderType, OrderStatus
import schemas
from datetime import datetime, timedelta
from typing import List, Optional, Tuple

def get_order_by_id(db: Session, order_id: int, user_id: int = None) -> Optional[Order]:
    """Get order by ID, optionally filtered by user."""
    query = db.query(Order).filter(Order.id == order_id)
    if user_id is not None:
        query = query.filter(Order.user_id == user_id)
    return query.first()

def get_user_orders(
    db: Session,
    user_id: int,
    skip: int = 0,
    limit: int = 100,
    order_type: Optional[OrderType] = None,
    status: Optional[OrderStatus] = None
) -> Tuple[List[Order], int]:
    """Get user orders with optional filtering and pagination."""
    query = db.query(Order).filter(Order.user_id == user_id)
    
    # Apply filters
    if order_type:
        query = query.filter(Order.order_type == order_type)
    
    if status:
        query = query.filter(Order.status == status)
    
    # Get total count before pagination
    total = query.count()
    
    # Apply pagination and ordering
    orders = query.order_by(desc(Order.created_at)).offset(skip).limit(limit).all()
    
    return orders, total

def create_order(db: Session, order: schemas.OrderCreate, user_id: int, book_info: dict) -> Order:
    """Create a new order."""
    
    # Calculate total amount
    if order.order_type == OrderType.BUY:
        unit_price = book_info["price"]
        total_amount = unit_price * order.quantity
        rental_start_date = None
        rental_end_date = None
    else:  # RENT
        unit_price = book_info["rent_price"]
        total_amount = unit_price * order.rental_days * order.quantity
        rental_start_date = datetime.utcnow()
        rental_end_date = rental_start_date + timedelta(days=order.rental_days)
    
    db_order = Order(
        user_id=user_id,
        book_id=order.book_id,
        order_type=order.order_type,
        status=OrderStatus.CONFIRMED,  # Auto-confirm for simplicity
        
        # Book details (snapshot at time of order)
        book_title=book_info["title"],
        book_author=book_info["author"],
        book_isbn=book_info.get("isbn"),
        
        # Pricing
        unit_price=unit_price,
        quantity=order.quantity,
        total_amount=total_amount,
        
        # Rental details
        rental_days=order.rental_days,
        rental_start_date=rental_start_date,
        rental_end_date=rental_end_date,
        
        # Metadata
        notes=order.notes
    )
    
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

def update_order_status(db: Session, order_id: int, status_update: schemas.OrderStatusUpdate, user_id: int = None) -> Optional[Order]:
    """Update order status."""
    query = db.query(Order).filter(Order.id == order_id)
    if user_id is not None:
        query = query.filter(Order.user_id == user_id)
    
    db_order = query.first()
    if not db_order:
        return None
    
    db_order.status = status_update.status
    if status_update.notes:
        db_order.notes = status_update.notes
    
    db.commit()
    db.refresh(db_order)
    return db_order

def return_rental(db: Session, order_id: int, return_request: schemas.OrderReturnRequest, user_id: int) -> Optional[Order]:
    """Return a rental order."""
    db_order = db.query(Order).filter(
        and_(
            Order.id == order_id,
            Order.user_id == user_id,
            Order.order_type == OrderType.RENT,
            Order.status.in_([OrderStatus.CONFIRMED, OrderStatus.COMPLETED])
        )
    ).first()
    
    if not db_order:
        return None
    
    db_order.status = OrderStatus.RETURNED
    db_order.rental_returned_date = return_request.return_date or datetime.utcnow()
    if return_request.notes:
        db_order.notes = return_request.notes
    
    db.commit()
    db.refresh(db_order)
    return db_order

def get_user_order_summary(db: Session, user_id: int) -> schemas.OrderSummary:
    """Get order summary for a user."""
    orders = db.query(Order).filter(Order.user_id == user_id).all()
    
    total_orders = len(orders)
    total_purchases = len([o for o in orders if o.order_type == OrderType.BUY])
    total_rentals = len([o for o in orders if o.order_type == OrderType.RENT])
    total_amount_spent = sum(o.total_amount for o in orders if o.status != OrderStatus.CANCELLED)
    active_rentals = len([
        o for o in orders 
        if o.order_type == OrderType.RENT 
        and o.status in [OrderStatus.CONFIRMED, OrderStatus.COMPLETED]
        and o.rental_returned_date is None
    ])
    
    return schemas.OrderSummary(
        total_orders=total_orders,
        total_purchases=total_purchases,
        total_rentals=total_rentals,
        total_amount_spent=total_amount_spent,
        active_rentals=active_rentals
    )

def get_active_rentals(db: Session, user_id: int) -> List[Order]:
    """Get active rental orders for a user."""
    return db.query(Order).filter(
        and_(
            Order.user_id == user_id,
            Order.order_type == OrderType.RENT,
            Order.status.in_([OrderStatus.CONFIRMED, OrderStatus.COMPLETED]),
            Order.rental_returned_date.is_(None)
        )
    ).order_by(Order.rental_end_date).all()

def get_overdue_rentals(db: Session, user_id: int = None) -> List[Order]:
    """Get overdue rental orders."""
    query = db.query(Order).filter(
        and_(
            Order.order_type == OrderType.RENT,
            Order.status.in_([OrderStatus.CONFIRMED, OrderStatus.COMPLETED]),
            Order.rental_returned_date.is_(None),
            Order.rental_end_date < datetime.utcnow()
        )
    )
    
    if user_id is not None:
        query = query.filter(Order.user_id == user_id)
    
    return query.order_by(Order.rental_end_date).all()

def get_all_orders(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    order_type: Optional[OrderType] = None,
    status: Optional[OrderStatus] = None
) -> Tuple[List[Order], int]:
    """Get all orders across all users (admin only)."""
    query = db.query(Order)
    
    # Apply filters
    if order_type:
        query = query.filter(Order.order_type == order_type)
    
    if status:
        query = query.filter(Order.status == status)
    
    # Get total count before pagination
    total = query.count()
    
    # Apply pagination and ordering
    orders = query.order_by(desc(Order.created_at)).offset(skip).limit(limit).all()
    
    return orders, total

def get_admin_summary(db: Session) -> dict:
    """Get admin summary with global statistics."""
    all_orders = db.query(Order).all()
    
    total_orders = len(all_orders)
    total_purchases = len([o for o in all_orders if o.order_type == OrderType.BUY])
    total_rentals = len([o for o in all_orders if o.order_type == OrderType.RENT])
    total_revenue = sum(o.total_amount for o in all_orders if o.status != OrderStatus.CANCELLED)
    active_rentals = len([
        o for o in all_orders 
        if o.order_type == OrderType.RENT 
        and o.status in [OrderStatus.CONFIRMED, OrderStatus.COMPLETED]
        and o.rental_returned_date is None
    ])
    overdue_rentals = len(get_overdue_rentals(db))
    
    return {
        "total_orders": total_orders,
        "total_purchases": total_purchases,
        "total_rentals": total_rentals,
        "total_revenue": total_revenue,
        "active_rentals": active_rentals,
        "overdue_rentals": overdue_rentals
    }
