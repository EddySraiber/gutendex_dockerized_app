#!/bin/bash
set -e

# Ensure all directories exist with correct permissions
mkdir -p /app/catalog_files/tmp/cache/epub
mkdir -p /app/catalog_files/rdf
mkdir -p /app/catalog_files/log
chmod -R 777 /app/catalog_files

# Apply database migrations
python manage.py migrate

# Check for existing catalog archive
CATALOG_ARCHIVE="/app/catalog_files/tmp/tar.tz2"
if [ -f "$CATALOG_ARCHIVE" ]; then
    tar -xjf "$CATALOG_ARCHIVE" -C /app/catalog_files/tmp
fi

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
    python manage.py updatecatalog
    
    # Verify books were loaded
    BOOK_COUNT_AFTER=$(python -c "
    import os
    import django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gutendex.settings')
    django.setup()
    from books.models import Book
    print(Book.objects.count())
    ")
    
    if [ "$BOOK_COUNT_AFTER" -eq 0 ]; then
        echo "WARNING: Catalog update completed but no books were loaded."
    fi
fi

# Collect static files
python manage.py collectstatic --noinput --clear

# Start the server
gunicorn gutendex.wsgi:application --bind 0.0.0.0:8000