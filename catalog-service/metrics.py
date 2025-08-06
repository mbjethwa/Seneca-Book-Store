# Prometheus metrics for FastAPI services
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Response
import time
import logging

logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

ACTIVE_REQUESTS = Gauge(
    'http_requests_active',
    'Currently active HTTP requests'
)

ERROR_COUNT = Counter(
    'http_errors_total',
    'Total HTTP errors',
    ['method', 'endpoint', 'status']
)

# Service-specific metrics
USER_REGISTRATIONS = Counter(
    'user_registrations_total',
    'Total user registrations'
)

USER_LOGINS = Counter(
    'user_logins_total',
    'Total user logins',
    ['status']
)

BOOK_VIEWS = Counter(
    'book_views_total',
    'Total book views'
)

BOOK_SEARCHES = Counter(
    'book_searches_total',
    'Total book searches'
)

# Catalog-specific metrics
BOOKS_BROWSED = Counter(
    'books_browsed_total',
    'Total book browse requests'
)

BOOKS_VIEWED = Counter(
    'books_viewed_total',
    'Total individual book views'
)

CATALOG_SEARCH_QUERIES = Counter(
    'catalog_search_queries_total',
    'Total catalog search queries'
)

ORDERS_CREATED = Counter(
    'orders_created_total',
    'Total orders created',
    ['order_type']
)

ORDERS_VALUE = Counter(
    'orders_value_total',
    'Total value of orders',
    ['order_type']
)


class PrometheusMetrics:
    """Prometheus metrics collection for FastAPI applications."""
    
    def __init__(self, app_name: str):
        self.app_name = app_name
        
    def record_request(self, method: str, endpoint: str, status_code: int, duration: float):
        """Record a completed HTTP request."""
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status_code).inc()
        REQUEST_DURATION.labels(method=method, endpoint=endpoint).observe(duration)
        
        if status_code >= 400:
            ERROR_COUNT.labels(method=method, endpoint=endpoint, status=status_code).inc()
    
    def start_request(self):
        """Mark the start of an HTTP request."""
        ACTIVE_REQUESTS.inc()
        return time.time()
    
    def end_request(self):
        """Mark the end of an HTTP request."""
        ACTIVE_REQUESTS.dec()
    
    def record_user_registration(self):
        """Record a user registration."""
        USER_REGISTRATIONS.inc()
    
    def record_user_login(self, success: bool):
        """Record a user login attempt."""
        status = "success" if success else "failed"
        USER_LOGINS.labels(status=status).inc()
    
    def record_book_view(self):
        """Record a book view."""
        BOOK_VIEWS.inc()
    
    def record_book_search(self):
        """Record a book search."""
        BOOK_SEARCHES.inc()
    
    def record_order_created(self, order_type: str, value: float):
        """Record an order creation."""
        ORDERS_CREATED.labels(order_type=order_type).inc()
        ORDERS_VALUE.labels(order_type=order_type).inc(value)
    
    # Catalog service specific metrics
    @property
    def books_browsed(self):
        """Access to books browsed counter."""
        return BOOKS_BROWSED
    
    @property
    def books_viewed(self):
        """Access to books viewed counter."""
        return BOOKS_VIEWED
    
    @property
    def catalog_search_queries(self):
        """Access to catalog search queries counter."""
        return CATALOG_SEARCH_QUERIES
    
    def get_metrics(self):
        """Get Prometheus metrics in the expected format."""
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# Global metrics instance (will be initialized in each service)
metrics = None

def init_metrics(app_name: str):
    """Initialize metrics for the application."""
    global metrics
    metrics = PrometheusMetrics(app_name)
    logger.info(f"Prometheus metrics initialized for {app_name}")
    return metrics
