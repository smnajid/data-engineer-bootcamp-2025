#!/bin/bash

# Script to run NY Taxi data import using Docker

set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --url URL              URL of the Parquet file to download"
    echo "  --file FILE             Path to local Parquet file"
    echo "  --table TABLE           Target table name (default: yellow_tripdata_2025_01)"
    echo "  --chunksize SIZE        Number of rows per chunk (default: 100000)"
    echo "  --if-exists ACTION      Action if table exists: fail/replace/append (default: replace)"
    echo "  --dry-run               Show what would be done without importing"
    echo "  --verbose               Enable verbose output"
    echo "  --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --url https://example.com/data.parquet --table my_table"
    echo "  $0 --file /path/to/local/file.parquet --chunksize 50000"
    echo "  $0 --dry-run --verbose"
}

# Parse command line arguments
PYTHON_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            PYTHON_ARGS="$PYTHON_ARGS --url $2"
            shift 2
            ;;
        --file)
            PYTHON_ARGS="$PYTHON_ARGS --file $2"
            shift 2
            ;;
        --table)
            PYTHON_ARGS="$PYTHON_ARGS --table $2"
            shift 2
            ;;
        --chunksize)
            PYTHON_ARGS="$PYTHON_ARGS --chunksize $2"
            shift 2
            ;;
        --if-exists)
            PYTHON_ARGS="$PYTHON_ARGS --if-exists $2"
            shift 2
            ;;
        --dry-run)
            PYTHON_ARGS="$PYTHON_ARGS --dry-run"
            shift
            ;;
        --verbose)
            PYTHON_ARGS="$PYTHON_ARGS --verbose"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo "🚀 Starting NY Taxi Data Import Process..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Function to cleanup containers
cleanup() {
    echo "🧹 Cleaning up containers..."
    docker-compose down
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Start PostgreSQL and wait for it to be ready
echo "📦 Starting PostgreSQL container..."
docker-compose up -d postgres

echo "⏳ Waiting for PostgreSQL to be ready..."
docker-compose exec -T postgres pg_isready -U root -d ny_taxi

# Build and run the import script
echo "🔨 Building import script container..."
docker-compose build import-script

echo "📊 Running data import with arguments: $PYTHON_ARGS"
docker-compose run --rm import-script python ny_taxi_pg_import.py $PYTHON_ARGS

echo "✅ Import completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  - Access PgAdmin at http://localhost:8080 (admin@admin.com / admin)"
echo "  - Connect to PostgreSQL at localhost:5432"
echo "  - Database: ny_taxi, User: root, Password: root"
echo ""
echo "🛑 To stop all containers: docker-compose down"
