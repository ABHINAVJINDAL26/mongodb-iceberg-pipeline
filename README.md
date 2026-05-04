# DataZip Assignment: MongoDB to Apache Iceberg Data Pipeline using OLake

This repository contains the implementation for the data engineering assignment demonstrating a complete data pipeline that extracts data from MongoDB and synchronizes it into Apache Iceberg format using the OLake tool.

## 🚀 Architecture Overview
The pipeline consists of the following containerized services:
1. **MongoDB**: Acts as the data source with a single-node Replica Set enabled (required for CDC operations).
2. **MinIO (S3 Compatible)**: Acts as the storage layer for Apache Iceberg `.parquet` data files and metadata.
3. **PostgreSQL**: Acts as the JDBC catalog to store Iceberg table schema and structural metadata.
4. **OLake**: The core pipeline engine used to discover the MongoDB schema and sync data into the Iceberg destination.
5. **Apache Spark**: Used to query and verify the synchronized data from the Iceberg catalog.

---

## 🛠️ Setup Instructions

### Prerequisites
- Docker & Docker Compose installed on your system.

### Step 1: Start the Infrastructure
Clone this repository and spin up all the required databases and storage services using Docker Compose:
```bash
docker-compose up -d
```
This command starts MongoDB, MinIO, and PostgreSQL. Wait about 30 seconds for all services to become healthy.

### Step 2: Insert Sample Data into MongoDB
We will insert 15 sample records into the `shop.orders` collection.
```bash
docker exec -i primary_mongo mongosh shop < insert_data.js
```

### Step 3: Run OLake Pipeline
**1. Discover Schema**
Generate the `streams.json` file which identifies the collections and schema in the MongoDB source:
```bash
docker run --rm --network datazip_ass1mongodb_olake-net -v "${PWD}:/mnt/config" olakego/source-mongodb:latest discover --config /mnt/config/source.json > streams.json
```

**2. Sync Data to Iceberg**
Execute the pipeline to extract data from MongoDB and load it into the MinIO Iceberg bucket:
```bash
docker run --rm --network datazip_ass1mongodb_olake-net -v "${PWD}:/mnt/config" olakego/source-mongodb:latest sync --config /mnt/config/source.json --catalog /mnt/config/streams.json --destination /mnt/config/destination.json
```

### Step 4: Verify with Apache Spark
Run the Spark SQL container to connect to the Iceberg JDBC catalog and query the synced tables:
```bash
.\query_spark.ps1
```
*Note: This script mounts the required Iceberg and AWS JAR packages and opens the interactive `spark-sql>` prompt.*

---

## 📸 Query Results & Screenshots

Run the following queries in the Spark SQL prompt to verify the data:

**1. Show Tables**
```sql
SHOW TABLES IN olake_iceberg.shop;
```
*(Insert your screenshot here)*

**2. Select All Data**
```sql
SELECT * FROM olake_iceberg.shop.orders;
```
*(Insert your screenshot here)*

**3. Run Aggregation - City-wise Total Sales**
```sql
SELECT city, COUNT(*) as orders, SUM(amount) as total_sales FROM olake_iceberg.shop.orders GROUP BY city ORDER BY total_sales DESC;
```
*(Insert your screenshot here)*

---

## 🚧 Challenges Faced

1. **MongoDB Replica Set Initialization in Docker**: 
   - *Challenge*: Setting up a MongoDB replica set with strict KeyFile authentication caused infinite crash loops in Docker Compose due to permission errors on the `mongo-keyfile` on Windows environments.
   - *Resolution*: Dropped the complex authorization rules and configured a simpler, single-node MongoDB replica set using a custom entrypoint script (`rs.initiate()`) which immediately fulfilled OLake's requirement for the Oplog without the overhead of KeyFiles.

2. **Spark SQL Network Binding on Docker Desktop (Windows)**:
   - *Challenge*: Running the `apache/spark:3.5.0` image locally threw a `NullPointerException` at the `BlockManagerMasterEndpoint`. This is a known hostname resolution bug when running Spark locally on Docker Desktop.
   - *Resolution*: Fixed this by explicitly passing `--hostname localhost` and configuring `--conf spark.driver.bindAddress=127.0.0.1` and `--conf spark.driver.host=127.0.0.1` in the `docker run` command.

## 💡 Proposed Improvements
- **Production-Ready Secrets Management**: In this local deployment, credentials (like MinIO keys and DB passwords) are stored in plaintext JSON files and environment variables. Moving to production, these should be managed via HashiCorp Vault or AWS Secrets Manager.
- **Incremental Syncs**: Implement a cron-job or Airflow DAG to continuously trigger OLake syncs to process CDC (Change Data Capture) streams from MongoDB instead of manual syncs.
- **Data Quality Checks**: Integrate a testing framework like Great Expectations after the OLake sync step to validate the integrity of the data before downstream Spark transformations.
