"""
Open Library API Integration Service
Provides access to Open Library's vast collection of books with covers and metadata.
"""

import httpx
import logging
from typing import List, Dict, Optional, Any
from urllib.parse import quote
import asyncio

logger = logging.getLogger(__name__)

class OpenLibraryAPI:
    """Client for interacting with Open Library API."""
    
    BASE_URL = "https://openlibrary.org"
    COVERS_URL = "https://covers.openlibrary.org"
    SEARCH_URL = "https://openlibrary.org/search.json"
    SUBJECTS_URL = "https://openlibrary.org/subjects"
    
    def __init__(self, timeout: int = 10):
        self.timeout = timeout
        self.client = httpx.AsyncClient(timeout=timeout)
    
    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()
    
    async def search_books(self, query: str, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
        """
        Search for books using Open Library search API.
        
        Args:
            query: Search query (title, author, ISBN, etc.)
            limit: Maximum number of results to return
            offset: Number of results to skip
            
        Returns:
            Dictionary containing search results and metadata
        """
        try:
            params = {
                "q": query,
                "limit": limit,
                "offset": offset,
                "fields": "key,title,author_name,first_publish_year,isbn,cover_i,publisher,subject,language,edition_count"
            }
            
            response = await self.client.get(self.SEARCH_URL, params=params)
            response.raise_for_status()
            data = response.json()
            
            # Transform the data to our format
            books = []
            for doc in data.get("docs", []):
                book = self._transform_search_result(doc)
                if book:
                    books.append(book)
            
            return {
                "books": books,
                "total": data.get("numFound", 0),
                "offset": offset,
                "limit": limit
            }
            
        except Exception as e:
            logger.error(f"Error searching books: {str(e)}")
            return {"books": [], "total": 0, "offset": offset, "limit": limit}
    
    async def get_books_by_subject(self, subject: str, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
        """
        Get books by subject category from Open Library.
        
        Args:
            subject: Subject category (e.g., 'science_fiction', 'history', 'romance')
            limit: Maximum number of results to return
            offset: Number of results to skip
            
        Returns:
            Dictionary containing books and metadata
        """
        try:
            # Clean and format subject
            subject = subject.lower().replace(" ", "_").replace("-", "_")
            url = f"{self.SUBJECTS_URL}/{subject}.json"
            
            params = {
                "limit": limit,
                "offset": offset,
                "details": "true"
            }
            
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            
            # Transform the data to our format
            books = []
            for work in data.get("works", []):
                book = self._transform_subject_result(work)
                if book:
                    books.append(book)
            
            return {
                "books": books,
                "total": data.get("work_count", 0),
                "offset": offset,
                "limit": limit,
                "subject": subject
            }
            
        except Exception as e:
            logger.error(f"Error getting books by subject '{subject}': {str(e)}")
            return {"books": [], "total": 0, "offset": offset, "limit": limit, "subject": subject}
    
    async def get_book_by_isbn(self, isbn: str) -> Optional[Dict[str, Any]]:
        """
        Get book details by ISBN.
        
        Args:
            isbn: Book ISBN (10 or 13 digits)
            
        Returns:
            Book details dictionary or None if not found
        """
        try:
            url = f"{self.BASE_URL}/isbn/{isbn}.json"
            response = await self.client.get(url)
            
            if response.status_code == 404:
                return None
                
            response.raise_for_status()
            data = response.json()
            
            return self._transform_isbn_result(data, isbn)
            
        except Exception as e:
            logger.error(f"Error getting book by ISBN '{isbn}': {str(e)}")
            return None
    
    async def get_popular_subjects(self) -> List[str]:
        """
        Get list of popular subject categories.
        
        Returns:
            List of popular subject names
        """
        popular_subjects = [
            "science_fiction",
            "fantasy",
            "mystery",
            "romance",
            "thriller",
            "history",
            "biography",
            "philosophy",
            "science",
            "technology",
            "business",
            "self_help",
            "fiction",
            "non_fiction",
            "young_adult",
            "children",
            "poetry",
            "drama",
            "humor",
            "travel"
        ]
        return popular_subjects
    
    def get_cover_url(self, cover_id: Optional[int] = None, isbn: Optional[str] = None, size: str = "M") -> Optional[str]:
        """
        Generate cover image URL.
        
        Args:
            cover_id: Open Library cover ID
            isbn: Book ISBN
            size: Image size ('S', 'M', 'L')
            
        Returns:
            Cover image URL or None
        """
        if cover_id:
            return f"{self.COVERS_URL}/b/id/{cover_id}-{size}.jpg"
        elif isbn:
            return f"{self.COVERS_URL}/b/isbn/{isbn}-{size}.jpg"
        return None
    
    def _transform_search_result(self, doc: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Transform Open Library search result to our book format."""
        try:
            # Extract basic information
            title = doc.get("title", "Unknown Title")
            author_names = doc.get("author_name", [])
            author = ", ".join(author_names) if author_names else "Unknown Author"
            
            # Get first ISBN if available
            isbn_list = doc.get("isbn", [])
            isbn = isbn_list[0] if isbn_list else None
            
            # Cover image
            cover_id = doc.get("cover_i")
            cover_url = self.get_cover_url(cover_id=cover_id, isbn=isbn)
            
            # Additional metadata
            publication_year = doc.get("first_publish_year")
            publishers = doc.get("publisher", [])
            publisher = publishers[0] if publishers else None
            subjects = doc.get("subject", [])
            languages = doc.get("language", [])
            
            return {
                "title": title,
                "author": author,
                "isbn": isbn,
                "cover_url": cover_url,
                "publication_year": publication_year,
                "publisher": publisher,
                "subjects": subjects[:5] if subjects else [],  # Limit subjects
                "languages": languages[:3] if languages else [],  # Limit languages
                "edition_count": doc.get("edition_count", 1),
                "key": doc.get("key", ""),
                "source": "open_library"
            }
            
        except Exception as e:
            logger.error(f"Error transforming search result: {str(e)}")
            return None
    
    def _transform_subject_result(self, work: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Transform Open Library subject result to our book format."""
        try:
            title = work.get("title", "Unknown Title")
            
            # Authors
            authors = work.get("authors", [])
            author_names = []
            for author in authors:
                if isinstance(author, dict):
                    author_names.append(author.get("name", "Unknown"))
                else:
                    author_names.append(str(author))
            author = ", ".join(author_names) if author_names else "Unknown Author"
            
            # Cover and key
            cover_id = work.get("cover_id")
            key = work.get("key", "")
            
            # Extract potential ISBN from the work
            isbn = None
            if "isbn" in work:
                isbn_list = work["isbn"] if isinstance(work["isbn"], list) else [work["isbn"]]
                isbn = isbn_list[0] if isbn_list else None
            
            cover_url = self.get_cover_url(cover_id=cover_id, isbn=isbn)
            
            return {
                "title": title,
                "author": author,
                "isbn": isbn,
                "cover_url": cover_url,
                "publication_year": work.get("first_publish_year"),
                "subjects": work.get("subject", [])[:5],
                "key": key,
                "source": "open_library"
            }
            
        except Exception as e:
            logger.error(f"Error transforming subject result: {str(e)}")
            return None
    
    def _transform_isbn_result(self, data: Dict[str, Any], isbn: str) -> Dict[str, Any]:
        """Transform Open Library ISBN result to our book format."""
        try:
            title = data.get("title", "Unknown Title")
            
            # Authors
            authors = data.get("authors", [])
            author_names = []
            for author in authors:
                if isinstance(author, dict):
                    # This might be a reference, we'd need another API call
                    author_names.append("Unknown Author")
                else:
                    author_names.append(str(author))
            author = ", ".join(author_names) if author_names else "Unknown Author"
            
            # Cover
            cover_url = self.get_cover_url(isbn=isbn)
            
            return {
                "title": title,
                "author": author,
                "isbn": isbn,
                "cover_url": cover_url,
                "publication_year": data.get("publish_date"),
                "publisher": ", ".join(data.get("publishers", [])),
                "description": data.get("description", {}).get("value") if isinstance(data.get("description"), dict) else data.get("description"),
                "subjects": data.get("subjects", [])[:5],
                "key": data.get("key", ""),
                "source": "open_library"
            }
            
        except Exception as e:
            logger.error(f"Error transforming ISBN result: {str(e)}")
            return {
                "title": "Unknown Title",
                "author": "Unknown Author",
                "isbn": isbn,
                "cover_url": self.get_cover_url(isbn=isbn),
                "source": "open_library"
            }

# Global instance
open_library_api = OpenLibraryAPI()
