# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the import script
COPY ny_taxi_pg_import.py .

# Create temp directory for downloads
RUN mkdir -p temp_downloads

# Set environment variables for database connection
ENV POSTGRES_USER=root
ENV POSTGRES_PASSWORD=root
ENV POSTGRES_DB=ny_taxi
ENV POSTGRES_HOST=my-postgres
ENV POSTGRES_PORT=5432

# Default command to run the import script
CMD ["python", "ny_taxi_pg_import.py"]
