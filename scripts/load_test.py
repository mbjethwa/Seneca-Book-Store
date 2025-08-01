#!/usr/bin/env python3
"""
Load Testing Script for Seneca Book Store
Tests /books and /orders endpoints under various load conditions
"""

import requests
import time
import json
import threading
import concurrent.futures
import statistics
import argparse
from typing import List, Dict, Any
from dataclasses import dataclass
import random


@dataclass
class LoadTestResult:
    """Results from a load test."""
    total_requests: int
    successful_requests: int
    failed_requests: int
    average_response_time: float
    min_response_time: float
    max_response_time: float
    requests_per_second: float
    success_rate: float


class LoadTester:
    """Load testing utility for API endpoints."""
    
    def __init__(self, base_url: str = "http://localhost:8002"):
        self.base_url = base_url
        self.user_token = None
        self.admin_token = None
        
    def authenticate(self):
        """Authenticate and get tokens for testing."""
        # Get user token
        user_login = {
            "email": "user@seneca.ca",
            "password": "user123"
        }
        
        try:
            response = requests.post(f"http://localhost:8001/login", json=user_login)
            if response.status_code == 200:
                self.user_token = response.json()["access_token"]
        except Exception as e:
            print(f"Failed to get user token: {e}")
            
        # Get admin token
        admin_login = {
            "email": "admin@seneca.ca", 
            "password": "admin123"
        }
        
        try:
            response = requests.post(f"http://localhost:8001/login", json=admin_login)
            if response.status_code == 200:
                self.admin_token = response.json()["access_token"]
        except Exception as e:
            print(f"Failed to get admin token: {e}")
    
    def make_request(self, endpoint: str, method: str = "GET", data: Dict = None, 
                    use_auth: bool = False, use_admin: bool = False) -> Dict[str, Any]:
        """Make a single HTTP request and measure response time."""
        url = f"{self.base_url}{endpoint}"
        headers = {}
        
        if use_auth and self.user_token:
            headers["Authorization"] = f"Bearer {self.user_token}"
        elif use_admin and self.admin_token:
            headers["Authorization"] = f"Bearer {self.admin_token}"
            
        start_time = time.time()
        
        try:
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method == "POST":
                response = requests.post(url, json=data, headers=headers, timeout=10)
            else:
                raise ValueError(f"Unsupported method: {method}")
                
            end_time = time.time()
            
            return {
                "success": response.status_code < 400,
                "status_code": response.status_code,
                "response_time": end_time - start_time,
                "content_length": len(response.content)
            }
            
        except Exception as e:
            end_time = time.time()
            return {
                "success": False,
                "status_code": 0,
                "response_time": end_time - start_time,
                "error": str(e),
                "content_length": 0
            }
    
    def load_test_endpoint(self, endpoint: str, num_requests: int, 
                          concurrent_users: int, method: str = "GET",
                          data: Dict = None, use_auth: bool = False,
                          use_admin: bool = False) -> LoadTestResult:
        """Perform load test on a specific endpoint."""
        results = []
        
        def worker():
            """Worker function for concurrent requests."""
            result = self.make_request(endpoint, method, data, use_auth, use_admin)
            results.append(result)
        
        # Execute concurrent requests
        start_time = time.time()
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = [executor.submit(worker) for _ in range(num_requests)]
            concurrent.futures.wait(futures)
        
        end_time = time.time()
        total_time = end_time - start_time
        
        # Calculate statistics
        successful = [r for r in results if r["success"]]
        failed = [r for r in results if not r["success"]]
        response_times = [r["response_time"] for r in results]
        
        return LoadTestResult(
            total_requests=len(results),
            successful_requests=len(successful),
            failed_requests=len(failed),
            average_response_time=statistics.mean(response_times) if response_times else 0,
            min_response_time=min(response_times) if response_times else 0,
            max_response_time=max(response_times) if response_times else 0,
            requests_per_second=len(results) / total_time if total_time > 0 else 0,
            success_rate=len(successful) / len(results) if results else 0
        )


class BookStoreLoadTester:
    """Specialized load tester for Seneca Book Store endpoints."""
    
    def __init__(self, catalog_url: str = "http://localhost:8002", 
                 order_url: str = "http://localhost:8003"):
        self.catalog_tester = LoadTester(catalog_url)
        self.order_tester = LoadTester(order_url)
        
        # Authenticate both testers
        self.catalog_tester.authenticate()
        self.order_tester.authenticate()
    
    def test_books_endpoint(self, num_requests: int = 100, concurrent_users: int = 10):
        """Load test the /books endpoint."""
        print(f"\n📚 Testing /books endpoint...")
        print(f"Requests: {num_requests}, Concurrent Users: {concurrent_users}")
        
        # Test basic book listing
        result = self.catalog_tester.load_test_endpoint(
            "/books", num_requests, concurrent_users
        )
        
        self._print_results("GET /books", result)
        
        # Test book search
        search_result = self.catalog_tester.load_test_endpoint(
            "/books?search=python&page=1&size=10", 
            num_requests // 2, concurrent_users
        )
        
        self._print_results("GET /books (with search)", search_result)
        
        return result, search_result
    
    def test_orders_endpoint(self, num_requests: int = 50, concurrent_users: int = 5):
        """Load test the /orders endpoint."""
        print(f"\n🛒 Testing /orders endpoint...")
        print(f"Requests: {num_requests}, Concurrent Users: {concurrent_users}")
        
        # Test getting user orders
        get_orders_result = self.order_tester.load_test_endpoint(
            "/orders", num_requests, concurrent_users, use_auth=True
        )
        
        self._print_results("GET /orders", get_orders_result)
        
        # Test creating orders (smaller load due to side effects)
        sample_order = {
            "book_id": 1,
            "order_type": "buy",
            "quantity": 1
        }
        
        create_orders_result = self.order_tester.load_test_endpoint(
            "/orders", num_requests // 10, concurrent_users // 2,
            method="POST", data=sample_order, use_auth=True
        )
        
        self._print_results("POST /orders", create_orders_result)
        
        return get_orders_result, create_orders_result
    
    def test_mixed_workload(self, duration_seconds: int = 30):
        """Test mixed workload simulating real user behavior."""
        print(f"\n🔄 Testing mixed workload for {duration_seconds} seconds...")
        
        results = []
        end_time = time.time() + duration_seconds
        
        def simulate_user_session():
            """Simulate a realistic user session."""
            while time.time() < end_time:
                # Browse books (70% of requests)
                if random.random() < 0.7:
                    result = self.catalog_tester.make_request("/books")
                    results.append(("browse_books", result))
                
                # Search for books (20% of requests)
                elif random.random() < 0.9:
                    search_term = random.choice(["python", "java", "web", "data"])
                    result = self.catalog_tester.make_request(f"/books?search={search_term}")
                    results.append(("search_books", result))
                
                # Create order (10% of requests)
                else:
                    order_data = {
                        "book_id": random.randint(1, 10),
                        "order_type": random.choice(["buy", "rent"]),
                        "quantity": 1
                    }
                    result = self.order_tester.make_request(
                        "/orders", method="POST", data=order_data, use_auth=True
                    )
                    results.append(("create_order", result))
                
                # Random delay between requests (0.1 to 2 seconds)
                time.sleep(random.uniform(0.1, 2.0))
        
        # Run with multiple concurrent users
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(simulate_user_session) for _ in range(10)]
            concurrent.futures.wait(futures)
        
        # Analyze mixed workload results
        self._analyze_mixed_results(results)
    
    def _print_results(self, test_name: str, result: LoadTestResult):
        """Print formatted test results."""
        print(f"\n📊 Results for {test_name}:")
        print(f"  Total Requests: {result.total_requests}")
        print(f"  Successful: {result.successful_requests}")
        print(f"  Failed: {result.failed_requests}")
        print(f"  Success Rate: {result.success_rate:.2%}")
        print(f"  Average Response Time: {result.average_response_time:.3f}s")
        print(f"  Min Response Time: {result.min_response_time:.3f}s")
        print(f"  Max Response Time: {result.max_response_time:.3f}s")
        print(f"  Requests/Second: {result.requests_per_second:.2f}")
        
        # Performance assessment
        if result.success_rate >= 0.99:
            print("  ✅ Excellent reliability")
        elif result.success_rate >= 0.95:
            print("  ✅ Good reliability")
        else:
            print("  ⚠️  Poor reliability")
            
        if result.average_response_time <= 0.5:
            print("  ✅ Excellent performance")
        elif result.average_response_time <= 1.0:
            print("  ✅ Good performance")
        else:
            print("  ⚠️  Poor performance")
    
    def _analyze_mixed_results(self, results: List):
        """Analyze results from mixed workload test."""
        by_operation = {}
        
        for operation, result in results:
            if operation not in by_operation:
                by_operation[operation] = []
            by_operation[operation].append(result)
        
        print(f"\n📈 Mixed Workload Analysis:")
        print(f"  Total Operations: {len(results)}")
        
        for operation, ops in by_operation.items():
            successful = sum(1 for op in ops if op["success"])
            avg_time = statistics.mean([op["response_time"] for op in ops])
            success_rate = successful / len(ops)
            
            print(f"  {operation}:")
            print(f"    Count: {len(ops)}")
            print(f"    Success Rate: {success_rate:.2%}")
            print(f"    Avg Response Time: {avg_time:.3f}s")


def main():
    """Main function to run load tests."""
    parser = argparse.ArgumentParser(description="Load test Seneca Book Store APIs")
    parser.add_argument("--requests", type=int, default=100, 
                       help="Number of requests per test")
    parser.add_argument("--users", type=int, default=10,
                       help="Number of concurrent users")
    parser.add_argument("--duration", type=int, default=30,
                       help="Duration for mixed workload test (seconds)")
    parser.add_argument("--catalog-url", default="http://localhost:8002",
                       help="Catalog service URL")
    parser.add_argument("--order-url", default="http://localhost:8003",
                       help="Order service URL")
    
    args = parser.parse_args()
    
    print("🚀 Starting Seneca Book Store Load Testing")
    print("=" * 50)
    
    # Initialize tester
    tester = BookStoreLoadTester(args.catalog_url, args.order_url)
    
    try:
        # Test books endpoint
        book_results = tester.test_books_endpoint(args.requests, args.users)
        
        # Test orders endpoint
        order_results = tester.test_orders_endpoint(args.requests // 2, args.users // 2)
        
        # Test mixed workload
        tester.test_mixed_workload(args.duration)
        
        print(f"\n🎉 Load testing completed successfully!")
        print("=" * 50)
        
    except KeyboardInterrupt:
        print("\n⏹️  Load testing interrupted by user")
    except Exception as e:
        print(f"\n❌ Load testing failed: {e}")


if __name__ == "__main__":
    main()
