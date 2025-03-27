#!/bin/bash
set -e

echo "Starting PostgreSQL container..."
docker-compose up -d

echo "Waiting for PostgreSQL to be ready..."
sleep 5

echo "Creating a test table..."
docker-compose exec db psql -U gutendex -c "
CREATE TABLE IF NOT EXISTS test_persistence (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo "Inserting test data..."
docker-compose exec db psql -U gutendex -c "
INSERT INTO test_persistence (message) VALUES ('Test message at $(date)');"

echo "Current data in test table:"
docker-compose exec db psql -U gutendex -c "SELECT * FROM test_persistence;"

echo "Stopping and removing containers (but keeping volumes)..."
docker-compose down

echo "Starting containers again..."
docker-compose up -d

echo "Waiting for PostgreSQL to be ready..."
sleep 5

echo "Checking if data persisted:"
docker-compose exec db psql -U gutendex -c "SELECT * FROM test_persistence;"

echo "Test completed successfully!"
