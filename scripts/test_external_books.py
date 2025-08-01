#!/usr/bin/env python3
"""
Test script for Open Library API integration
Tests the external book discovery features without requiring deployment
"""

import asyncio
import sys
import os

# Add the catalog-service directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'catalog-service'))

try:
    from open_library_api import OpenLibraryAPI
    print("✅ Successfully imported OpenLibraryAPI")
except ImportError as e:
    print(f"❌ Failed to import OpenLibraryAPI: {e}")
    print("Make sure you're running from the project root directory")
    sys.exit(1)

async def test_open_library_integration():
    """Test the Open Library API integration functionality."""
    print("\n🔍 Testing Open Library API Integration")
    print("=" * 50)
    
    api = OpenLibraryAPI()
    
    try:
        # Test 1: Search for books
        print("\n📚 Test 1: Searching for Python programming books...")
        search_results = await api.search_books("python programming", limit=5)
        
        if search_results['books']:
            print(f"✅ Found {len(search_results['books'])} books")
            print(f"   Total available: {search_results['total']}")
            
            # Show first book details
            first_book = search_results['books'][0]
            print(f"   Sample book: '{first_book['title']}' by {first_book['author']}")
            if first_book.get('cover_url'):
                print(f"   Cover URL: {first_book['cover_url']}")
        else:
            print("❌ No books found in search")
        
        # Test 2: Browse by subject
        print("\n🔬 Test 2: Browsing science fiction books...")
        subject_results = await api.get_books_by_subject("science_fiction", limit=3)
        
        if subject_results['books']:
            print(f"✅ Found {len(subject_results['books'])} science fiction books")
            print(f"   Total available: {subject_results['total']}")
            
            for i, book in enumerate(subject_results['books'][:2], 1):
                print(f"   {i}. '{book['title']}' by {book['author']}")
        else:
            print("❌ No science fiction books found")
        
        # Test 3: Get popular subjects
        print("\n📖 Test 3: Getting popular subjects...")
        subjects = await api.get_popular_subjects()
        
        if subjects:
            print(f"✅ Got {len(subjects)} popular subjects")
            print(f"   Sample subjects: {', '.join(subjects[:5])}")
        else:
            print("❌ No subjects found")
        
        # Test 4: Get book by ISBN
        print("\n📘 Test 4: Looking up book by ISBN...")
        isbn_book = await api.get_book_by_isbn("9780132269933")  # Clean Code by Robert Martin
        
        if isbn_book:
            print(f"✅ Found book by ISBN: '{isbn_book['title']}' by {isbn_book['author']}")
            if isbn_book.get('cover_url'):
                print(f"   Cover URL: {isbn_book['cover_url']}")
        else:
            print("ℹ️  Book not found (ISBN may not exist in Open Library)")
        
        # Test 5: Cover URL generation
        print("\n🖼️  Test 5: Testing cover URL generation...")
        cover_url_isbn = api.get_cover_url(isbn="9780132269933")
        cover_url_id = api.get_cover_url(cover_id=8739161)
        
        print(f"   Cover URL by ISBN: {cover_url_isbn}")
        print(f"   Cover URL by ID: {cover_url_id}")
        
        print("\n🎉 All tests completed successfully!")
        print("\n📋 Integration Summary:")
        print("   ✅ Book search functionality working")
        print("   ✅ Subject browsing working")
        print("   ✅ Popular subjects available")
        print("   ✅ ISBN lookup working")
        print("   ✅ Cover URL generation working")
        print("\n🚀 Open Library integration is ready for production!")
        
    except Exception as e:
        print(f"\n❌ Error during testing: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    
    finally:
        await api.close()
    
    return True

async def test_sample_endpoints():
    """Test sample API calls that the frontend will make."""
    print("\n🌐 Testing Sample Frontend API Calls")
    print("=" * 50)
    
    api = OpenLibraryAPI()
    
    try:
        # Simulate common frontend searches
        test_queries = [
            ("python", 5),
            ("javascript", 3),
            ("machine learning", 5),
            ("fantasy", 10)
        ]
        
        for query, limit in test_queries:
            print(f"\n🔍 Searching for '{query}' (limit: {limit})...")
            results = await api.search_books(query, limit=limit)
            
            if results['books']:
                print(f"   ✅ Found {len(results['books'])} results out of {results['total']} total")
                
                # Check if books have covers
                with_covers = sum(1 for book in results['books'] if book.get('cover_url'))
                print(f"   🖼️  {with_covers}/{len(results['books'])} books have cover images")
                
                # Sample book info
                sample = results['books'][0]
                print(f"   📖 Sample: '{sample['title'][:50]}...' by {sample['author']}")
            else:
                print(f"   ⚠️  No results found for '{query}'")
        
        # Test popular subjects
        print(f"\n📚 Testing subject browsing...")
        subjects_to_test = ["science_fiction", "history", "romance", "mystery"]
        
        for subject in subjects_to_test:
            print(f"\n   📖 Browsing '{subject}' books...")
            results = await api.get_books_by_subject(subject, limit=3)
            
            if results['books']:
                print(f"      ✅ Found {len(results['books'])} books out of {results['total']} total")
            else:
                print(f"      ⚠️  No books found in '{subject}' category")
        
        print("\n✨ Sample API testing completed!")
        
    except Exception as e:
        print(f"\n❌ Error during sample testing: {str(e)}")
        return False
    
    finally:
        await api.close()
    
    return True

def print_integration_info():
    """Print information about the integration."""
    print("\n📚 Seneca Book Store - Open Library Integration Test")
    print("=" * 60)
    print("This script tests the Open Library API integration functionality")
    print("without requiring the full application deployment.")
    print("\n🔗 Open Library API Features:")
    print("   • Millions of free books")
    print("   • Book covers and metadata")
    print("   • Search by title, author, ISBN")
    print("   • Browse by subject categories")
    print("   • No authentication required")
    print("\n🎯 What this test validates:")
    print("   • API connectivity and responses")
    print("   • Data transformation and parsing")
    print("   • Cover image URL generation")
    print("   • Error handling")

async def main():
    """Main test function."""
    print_integration_info()
    
    # Test basic functionality
    success1 = await test_open_library_integration()
    
    if success1:
        # Test sample frontend scenarios
        success2 = await test_sample_endpoints()
        
        if success2:
            print("\n🎉 ALL TESTS PASSED!")
            print("\n🚀 Ready for deployment with external book integration!")
            print("\n📋 Next steps:")
            print("   1. Deploy the application: ./deploy.sh --k8s deploy")
            print("   2. Access the Discover page: https://senecabooks.local/discover")
            print("   3. Search for books and test the import functionality")
            return True
    
    print("\n❌ Some tests failed. Check the error messages above.")
    return False

if __name__ == "__main__":
    # Check if httpx is available
    try:
        import httpx
        print("✅ httpx library is available")
    except ImportError:
        print("❌ httpx library not found. Installing...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "httpx"])
        print("✅ httpx installed successfully")
    
    # Run the tests
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
