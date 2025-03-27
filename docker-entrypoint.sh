#!/bin/bash
set -e

# Debug: Print all environment variables
echo "=== Environment Variables ==="
env

# Ensure all directories exist with correct permissions
echo "Ensuring directory structure..."
mkdir -p /app/catalog_files/tmp/cache/epub
mkdir -p /app/catalog_files/rdf
mkdir -p /app/catalog_files/log
chmod -R 777 /app/catalog_files

# Debug: List contents of tmp directory
echo "=== Contents of /app/catalog_files/tmp ==="
ls -la /app/catalog_files/tmp

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Check for existing catalog archive
echo "=== Checking for catalog archives ==="
find /app/catalog_files -name "*.tar*"

CATALOG_ARCHIVE="/app/catalog_files/tmp/tar.tz2"
if [ -f "$CATALOG_ARCHIVE" ]; then
    echo "Existing catalog archive found at $CATALOG_ARCHIVE. Extracting..."
    tar -xvjf "$CATALOG_ARCHIVE" -C /app/catalog_files/tmp
    echo "Extraction completed. Contents:"
    find /app/catalog_files/tmp -type d
fi

# Debug: List contents after extraction
echo "=== Contents after extraction ==="
find /app/catalog_files/tmp -type d

# Check if catalog data needs to be loaded
BOOK_COUNT=$(python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gutendex.settings')
django.setup()
from books.models import Book
print(Book.objects.count())
")

if [ "$BOOK_COUNT" -eq 0 ]; then
    echo "No books found in database. Running catalog update..."
    python manage.py updatecatalog --verbosity 2
    
    # Verify books were loaded
    BOOK_COUNT_AFTER=$(python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gutendex.settings')
django.setup()
from books.models import Book
print(Book.objects.count())
")
    
    echo "Books in database after update: $BOOK_COUNT_AFTER"
    
    if [ "$BOOK_COUNT_AFTER" -eq 0 ]; then
        echo "WARNING: Catalog update completed but no books were loaded."
    fi
else
    echo "Database already contains $BOOK_COUNT books. Skipping catalog update."
fi


# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear

# Start the server
echo "Starting Gutendex server..."
gunicorn gutendex.wsgi:application --bind 0.0.0.0:8000