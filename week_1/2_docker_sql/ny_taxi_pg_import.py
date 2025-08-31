#!/usr/bin/env python3
"""
NY Taxi Data Import Script

This script imports NY taxi trip data from a Parquet file into PostgreSQL.
It accepts command line arguments for database connection and file paths.
"""

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy import text
import time
import math
import argparse
import os
import sys
import requests
from urllib.parse import urlparse


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Import NY taxi trip data from Parquet file to PostgreSQL",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Database connection arguments
    parser.add_argument(
        "--user",
        default=os.getenv("POSTGRES_USER", "root"),
        help="PostgreSQL username"
    )
    parser.add_argument(
        "--password", "-p",
        default=os.getenv("POSTGRES_PASSWORD", "root"),
        help="PostgreSQL password"
    )
    parser.add_argument(
        "--host", "-H",
        default=os.getenv("POSTGRES_HOST", "localhost"),
        help="PostgreSQL host"
    )
    parser.add_argument(
        "--port", "-P",
        default=os.getenv("POSTGRES_PORT", "5432"),
        help="PostgreSQL port"
    )
    parser.add_argument(
        "--database", "-d",
        default=os.getenv("POSTGRES_DB", "ny_taxi"),
        help="PostgreSQL database name"
    )
    parser.add_argument(
        "--table", "-t",
        default="yellow_tripdata_2025_01",
        help="Target table name"
    )
    
    # File and processing arguments
    parser.add_argument(
        "--url", "-u",
        default="https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet",
        help="URL of the Parquet file to download and import"
    )
    parser.add_argument(
        "--file", "-f",
        help="Path to local Parquet file to import (alternative to --url)"
    )
    parser.add_argument(
        "--chunksize", "-c",
        type=int,
        default=100000,
        help="Number of rows to process in each chunk"
    )
    parser.add_argument(
        "--if-exists",
        choices=["fail", "replace", "append"],
        default="replace",
        help="How to behave if the table already exists"
    )
    
    # Optional arguments
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without actually importing data"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    
    return parser.parse_args()


def validate_file(file_path):
    """Validate that the Parquet file exists and is readable."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Parquet file not found: {file_path}")
    
    if not file_path.endswith('.parquet'):
        print(f"Warning: File {file_path} doesn't have .parquet extension")


def download_parquet_file(url, verbose=False):
    """Download Parquet file from URL and return the file path."""
    try:
        # Parse URL to get filename
        parsed_url = urlparse(url)
        filename = os.path.basename(parsed_url.path)
        if not filename:
            filename = "downloaded_data.parquet"
        
        # Create temp directory if it doesn't exist
        temp_dir = "temp_downloads"
        os.makedirs(temp_dir, exist_ok=True)
        
        file_path = os.path.join(temp_dir, filename)
        
        if verbose:
            print(f"Downloading from: {url}")
            print(f"Saving to: {file_path}")
        
        # Download the file
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Raise an exception for bad status codes
        
        total_size = int(response.headers.get('content-length', 0))
        downloaded_size = 0
        
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded_size += len(chunk)
                    if verbose and total_size > 0:
                        progress = (downloaded_size / total_size) * 100
                        print(f"\rDownload progress: {progress:.1f}%", end='', flush=True)
        
        if verbose:
            print(f"\nDownload completed: {file_path}")
        
        return file_path
        
    except requests.exceptions.RequestException as e:
        raise Exception(f"Failed to download file from {url}: {e}")
    except Exception as e:
        raise Exception(f"Error downloading file: {e}")


def get_data_source(args):
    """Determine data source (URL or local file) and return file path."""
    if args.file:
        # Use local file if specified
        return args.file
    else:
        # Download from URL
        return download_parquet_file(args.url, args.verbose)


def create_connection_string(args):
    """Create PostgreSQL connection string from arguments."""
    return f"postgresql+psycopg2://{args.user}:{args.password}@{args.host}:{args.port}/{args.database}"


def test_connection(engine):
    """Test database connection."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False


def main():
    """Main function to run the import process."""
    args = parse_arguments()
    
    # Get data source (download from URL or use local file)
    try:
        file_path = get_data_source(args)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Validate local file (if using local file)
    if args.file:
        try:
            validate_file(file_path)
        except FileNotFoundError as e:
            print(f"Error: {e}")
            sys.exit(1)
    
    if args.verbose:
        print(f"Reading Parquet file: {file_path}")
    
    # Read the Parquet file
    try:
        df = pd.read_parquet(file_path)
        if args.verbose:
            print(f"Loaded {len(df)} rows from Parquet file")
    except Exception as e:
        print(f"Error reading Parquet file: {e}")
        sys.exit(1)
    
    # Clean column names
    df.columns = [c.lower().replace(' ', '_') for c in df.columns]
    if args.verbose:
        print(f"Column names: {list(df.columns)}")
    
    # Convert datetime columns
    datetime_columns = ['tpep_pickup_datetime', 'tpep_dropoff_datetime']
    for col in datetime_columns:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col])
            if args.verbose:
                print(f"Converted {col} to datetime")
    
    # Create database connection
    connection_string = create_connection_string(args)
    engine = create_engine(connection_string)
    
    # Test connection
    if not test_connection(engine):
        print("Failed to connect to database. Please check your connection parameters.")
        sys.exit(1)
    
    if args.dry_run:
        print("DRY RUN MODE - No data will be imported")
        print(f"Would import {len(df)} rows to table '{args.table}'")
        print(f"Would use chunksize: {args.chunksize}")
        print(f"Would use if_exists: {args.if_exists}")
        # Clean up downloaded file if it was downloaded
        if not args.file and os.path.exists(file_path):
            try:
                os.remove(file_path)
                if args.verbose:
                    print(f"Cleaned up temporary file: {file_path}")
            except Exception as e:
                print(f"Warning: Could not clean up temporary file: {e}")
        return
    
    # Import data
    print(f"Starting import of {len(df)} rows to table '{args.table}'")
    
    # Create table schema with first chunk (if replacing)
    if args.if_exists == "replace":
        df.iloc[:0].to_sql(args.table, engine, if_exists="replace", index=False)
        if args.verbose:
            print(f"Created table '{args.table}' with schema")
    
    # Insert data in chunks
    chunksize = args.chunksize
    n_chunks = math.ceil(len(df) / chunksize)
    
    total_start = time.time()
    
    for i in range(n_chunks):
        start = time.time()
        chunk = df.iloc[i*chunksize : (i+1)*chunksize]
        
        if_exists_action = "append" if args.if_exists == "replace" else args.if_exists
        chunk.to_sql(args.table, engine, if_exists=if_exists_action, index=False)
        
        elapsed = time.time() - start
        print(f"Chunk {i+1}/{n_chunks} inserted ({len(chunk)} rows) in {elapsed:.2f} seconds")
    
    total_elapsed = time.time() - total_start
    print(f"Total import time: {total_elapsed:.2f} seconds")
    
    # Verify the import
    try:
        with engine.connect() as conn:
            result = conn.execute(text(f"SELECT COUNT(*) FROM {args.table}"))
            count = result.scalar()
            print(f"Total rows in table '{args.table}': {count}")
    except Exception as e:
        print(f"Warning: Could not verify row count: {e}")
    
    # Clean up downloaded file if it was downloaded
    if not args.file and os.path.exists(file_path):
        try:
            os.remove(file_path)
            if args.verbose:
                print(f"Cleaned up temporary file: {file_path}")
        except Exception as e:
            print(f"Warning: Could not clean up temporary file: {e}")


if __name__ == "__main__":
    main()



