from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Enum, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os
import enum

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./orders.db")

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class OrderType(enum.Enum):
    BUY = "buy"
    RENT = "rent"

class OrderStatus(enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    RETURNED = "returned"  # For rental returns

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    book_id = Column(Integer, nullable=False, index=True)
    order_type = Column(Enum(OrderType), nullable=False)
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING, nullable=False)
    
    # Book details at time of order (for historical record)
    book_title = Column(String, nullable=False)
    book_author = Column(String, nullable=False)
    book_isbn = Column(String, nullable=True)
    
    # Pricing
    unit_price = Column(Float, nullable=False)  # Price per unit (buy price or daily rent price)
    quantity = Column(Integer, default=1, nullable=False)
    total_amount = Column(Float, nullable=False)
    
    # Rental specific fields
    rental_days = Column(Integer, nullable=True)  # Only for rent orders
    rental_start_date = Column(DateTime, nullable=True)
    rental_end_date = Column(DateTime, nullable=True)
    rental_returned_date = Column(DateTime, nullable=True)
    
    # Order metadata
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
