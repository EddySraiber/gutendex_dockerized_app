#!/bin/bash
set -e

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Check if we need to download and import the catalog data
CATALOG_DIR="/app/catalog_files/rdf"
if [ ! -d "$CATALOG_DIR" ] || [ -z "$(ls -A $CATALOG_DIR 2>/dev/null)" ]; then
    echo "Catalog data not found. Downloading and importing catalog data..."
    python manage.py updatecatalog
else
    echo "Catalog data already exists. Skipping download."
fi

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Start the server
echo "Starting Gutendex server..."
gunicorn gutendex.wsgi:application --bind 0.0.0.0:8000
