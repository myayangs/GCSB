#!/bin/bash

# Set project ID
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET_NAME=$PROJECT_ID-bucket

# Load data into BigQuery
bq load --source_format=CSV --autodetect products.products_information gs://$BUCKET_NAME/products.csv 

# Create search index if not exists
bq query --use_legacy_sql=false "CREATE SEARCH INDEX IF NOT EXISTS products.p_i_search_index ON products.products_information (ALL COLUMNS);"

# Execute search query
bq query --use_legacy_sql=false "SELECT * FROM products.products_information WHERE SEARCH(STRUCT(), '22 oz Water Bottle') = TRUE;"
