#!/bin/bash
set -e

echo "===== GUTENDEX CATALOG DEBUGGING ====="

# Check catalog logs
echo "Checking application logs for catalog updates..."
docker-compose logs app | grep -i catalog

# Check if database tables exist
echo -e "\nChecking database tables..."
docker-compose exec db psql -U gutendex -c "\dt"

# Check book count directly from database
echo -e "\nChecking book count in database..."
docker-compose exec db psql -U gutendex -c "SELECT COUNT(*) FROM books_book;"

# Check for Arthur Conan Doyle in the database
echo -e "\nChecking for Arthur Conan Doyle in database..."
docker-compose exec db psql -U gutendex -c "SELECT COUNT(*) FROM books_author WHERE name ILIKE '%conan doyle%';"

# Check Django management commands
echo -e "\nListing available Django management commands..."
docker-compose exec app python manage.py help

# Check for errors in updatecatalog command
echo -e "\nTrying catalog update with high verbosity..."
docker-compose exec app python manage.py updatecatalog --verbosity 3

echo -e "\n===== DEBUGGING COMPLETE ====="
