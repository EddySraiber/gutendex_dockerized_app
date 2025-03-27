#!/bin/bash
set -e

echo "===== GUTENDEX APPLICATION VERIFICATION ====="

# Check if containers are running
echo -e "\n1. Checking container status..."
docker-compose ps

# Check application logs (last 20 lines)
echo -e "\n2. Checking application logs (last 20 lines)..."
docker-compose logs --tail=20 app

# Test API endpoint
echo -e "\n3. Testing API endpoint for Arthur Conan Doyle books..."
RESULT=$(curl -s http://localhost:8000/books/?search=arthur%20conan%20doyle | grep -o '"count": [0-9]*' | cut -d' ' -f2)

if [ -n "$RESULT" ]; then
    echo "Found $RESULT books by Arthur Conan Doyle"
    if [ "$RESULT" -eq 14 ]; then
        echo "✅ TEST PASSED: Found expected number of books (14)"
    else
        echo "❌ TEST FAILED: Expected 14 books, found $RESULT"
    fi
else
    echo "❌ TEST FAILED: Could not get valid response from API"
    echo "Response details:"
    curl -s http://localhost:8000/books/?search=arthur%20conan%20doyle | head -n 20
fi

# Check homepage access
echo -e "\n4. Checking homepage access..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ TEST PASSED: Homepage is accessible (HTTP 200)"
else
    echo "❌ TEST FAILED: Homepage is not accessible (HTTP $HTTP_CODE)"
fi

echo -e "\n===== VERIFICATION COMPLETE ====="