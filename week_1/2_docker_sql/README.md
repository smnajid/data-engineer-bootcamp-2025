# NY Taxi Data Import with Docker

This project provides a complete Docker-based solution for importing NYC taxi trip data from Parquet files into PostgreSQL.

## 🏗️ Architecture

- **PostgreSQL Container**: Database server with persistent storage
- **Import Script Container**: Python script that downloads and imports data
- **PgAdmin Container**: Web-based PostgreSQL administration tool (optional)

## 📁 Files

- `ny_taxi_pg_import.py` - Main import script with command-line arguments
- `Dockerfile` - Docker image for the import script
- `docker-compose.yml` - Orchestrates all containers
- `requirements.txt` - Python dependencies
- `run_import.sh` - Convenient script to run the entire process

## 🚀 Quick Start

### Option 1: Using the automated script (Recommended)

```bash
# Make sure you're in the week_1/2_docker_sql directory
cd week_1/2_docker_sql

# Run the import process
./run_import.sh
```

### Option 2: Manual Docker commands

```bash
# Start PostgreSQL container
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
docker-compose exec -T postgres pg_isready -U root -d ny_taxi

# Build and run import script
docker-compose build import-script
docker-compose run --rm import-script python ny_taxi_pg_import.py --verbose
```

### Option 3: Run import script directly in container

```bash
# Start all services
docker-compose up -d

# Run import with custom parameters
docker-compose run --rm import-script python ny_taxi_pg_import.py \
  --url "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-02.parquet" \
  --table "yellow_tripdata_2025_02" \
  --verbose
```

## 🔧 Configuration

### Environment Variables

The import script uses these environment variables (set in docker-compose.yml):

- `POSTGRES_USER=root`
- `POSTGRES_PASSWORD=root`
- `POSTGRES_DB=ny_taxi`
- `POSTGRES_HOST=postgres`
- `POSTGRES_PORT=5432`

### Command Line Options

```bash
# Basic usage
python ny_taxi_pg_import.py

# Download from specific URL
python ny_taxi_pg_import.py --url "https://example.com/data.parquet"

# Use local file instead
python ny_taxi_pg_import.py --file "/path/to/local/file.parquet"

# Custom database connection
python ny_taxi_pg_import.py --host myhost --user myuser --password mypass

# Custom table name
python ny_taxi_pg_import.py --table "my_custom_table"

# Append to existing table
python ny_taxi_pg_import.py --if-exists append

# Dry run (no actual import)
python ny_taxi_pg_import.py --dry-run --verbose

# Show help
python ny_taxi_pg_import.py --help
```

## 🌐 Access Points

After running the containers:

- **PostgreSQL**: `localhost:5432`
  - Database: `ny_taxi`
  - User: `root`
  - Password: `root`

- **PgAdmin**: `http://localhost:8080`
  - Email: `admin@admin.com`
  - Password: `admin`

## 📊 Data Source

By default, the script downloads January 2025 NYC taxi data from:
```
https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet
```

You can change this URL to download different months or years.

## 🛠️ Development

### Building the import container manually

```bash
docker build -t ny-taxi-importer .
```

### Running the import container manually

```bash
docker run --rm \
  --network ny_taxi_network \
  -e POSTGRES_HOST=postgres \
  ny-taxi-importer \
  python ny_taxi_pg_import.py --verbose
```

### Accessing the PostgreSQL container

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U root -d ny_taxi

# View tables
\dt

# Query data
SELECT COUNT(*) FROM yellow_tripdata_2025_01;
```

## 🧹 Cleanup

```bash
# Stop all containers
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Remove the import image
docker rmi ny-taxi-importer
```

## 🔍 Troubleshooting

### PostgreSQL connection issues
- Ensure the PostgreSQL container is running: `docker-compose ps`
- Check logs: `docker-compose logs postgres`
- Verify network connectivity: `docker network ls`

### Import script issues
- Check logs: `docker-compose logs import-script`
- Run with verbose mode: `--verbose`
- Test with dry run: `--dry-run`

### Permission issues
- Make sure the script is executable: `chmod +x run_import.sh`
- Check Docker permissions on your system

## 📝 Notes

- Data is persisted in `./ny_taxi_postgres_data/` directory
- Downloaded Parquet files are temporarily stored in `temp_downloads/`
- The import script automatically cleans up temporary files after processing
- The script supports chunked imports for large datasets
