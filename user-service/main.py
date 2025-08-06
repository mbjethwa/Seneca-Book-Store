from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import uvicorn
from datetime import timedelta
import logging
import time

# Import our modules
from database import get_db
from auth import create_access_token, verify_token, ACCESS_TOKEN_EXPIRE_MINUTES
import crud
import schemas
from metrics import init_metrics

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("user-service")

app = FastAPI(title="User Service", version="1.0.0", description="User management and authentication service")

# Initialize Prometheus metrics
metrics = init_metrics("user-service")

# Security
security = HTTPBearer()

@app.get("/metrics")
async def get_metrics():
    """Prometheus metrics endpoint."""
    return metrics.get_metrics()

@app.middleware("http")
async def log_and_monitor_requests(request: Request, call_next):
    """Log all API requests and collect Prometheus metrics."""
    start_time = metrics.start_request()
    
    # Extract user info if available
    user_info = "anonymous"
    try:
        if "authorization" in request.headers:
            auth_header = request.headers["authorization"]
            if auth_header.startswith("Bearer "):
                token = auth_header.split(" ")[1]
                email = verify_token(token)
                if email:
                    user_info = email
    except Exception:
        pass  # Keep as anonymous if token verification fails
    
    # Process request
    response = await call_next(request)
    
    # Calculate processing time
    process_time = time.time() - start_time
    metrics.end_request()
    
    # Record metrics
    endpoint = request.url.path
    metrics.record_request(request.method, endpoint, response.status_code, process_time)
    
    # Log the request
    logger.info(
        f"Method: {request.method} | "
        f"Path: {endpoint} | "
        f"User: {user_info} | "
        f"Status: {response.status_code} | "
        f"Time: {process_time:.3f}s"
    )
    
    return response

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    """Get current authenticated user."""
    token = credentials.credentials
    email = verify_token(token)
    if email is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = crud.get_user_by_email(db, email=email)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

@app.get("/")
async def health_check():
    return {"status": "healthy", "service": "user-service"}

@app.get("/health")
async def health():
    return {"status": "OK", "service": "user-service"}

@app.post("/register", response_model=schemas.UserResponse)
async def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Register a new user."""
    # Check if user already exists
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    new_user = crud.create_user(db=db, user=user)
    
    # Record metrics
    metrics.record_user_registration()
    
    return new_user

@app.post("/login", response_model=schemas.LoginResponse)
async def login_user(user_credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    """Login user and return JWT token."""
    user = crud.authenticate_user(db, user_credentials.email, user_credentials.password)
    
    if not user:
        # Record failed login
        metrics.record_user_login(success=False)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Record successful login
    metrics.record_user_login(success=True)
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user": schemas.UserResponse.model_validate(user)
    }

@app.get("/me", response_model=schemas.UserResponse)
async def read_users_me(current_user: schemas.UserResponse = Depends(get_current_user)):
    """Get current user information."""
    return current_user

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
