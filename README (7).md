# Assignment 1 — MongoDB → Apache Iceberg Data Pipeline using OLake

## 📌 What is This Assignment?

Is assignment mein humein ek **data pipeline** banana hai jo:

1. **MongoDB** (source database) se data uthata hai
2. **OLake** (tool) use karke data ko **Apache Iceberg** format mein convert karta hai
3. **Hive Metastore** schema track karta hai
4. **Apache Spark** se Iceberg tables ko query karta hai

### Real Life Analogy
```
MongoDB          →       OLake        →      Apache Iceberg      →     Spark SQL
(dukaan ka          (delivery boy —         (modern digital          (boss reports
 register)           data uthata aur         warehouse)               nikalta hai)
                     pohchata hai)
```

---

## 🛠️ Tech Stack

| Tool | Kya Karta Hai |
|------|--------------|
| **MongoDB** | Source database — yahan orders ka data store hoga |
| **OLake** | Data sync tool — MongoDB se data uthake Iceberg mein dalta hai |
| **Apache Iceberg** | Modern table format — data efficiently store karta hai |
| **Hive Metastore** | Schema registry — track karta hai ki kaunsi table kahan hai |
| **MinIO** | Local S3 storage — Iceberg ki actual data files yahan save hongi |
| **Apache Spark** | Query engine — Iceberg tables ko SQL se query karta hai |
| **Docker** | Saari services ek saath chalane ke liye |

---

## 📁 Project Folder Structure

```
olake-mongodb-pipeline/
├── docker-compose.yml       ← saari Docker services
├── source.json              ← OLake ka MongoDB connection config
├── destination.json         ← OLake ka Iceberg destination config
├── streams.json             ← discover command ke baad auto-generate hogi
└── data/
    └── minio-data/          ← Iceberg files yahan store hongi
```

---

## 🚀 Step-by-Step Setup Guide

### Prerequisites

- Docker Desktop installed aur running ho
- Windows PowerShell ya Command Prompt

---

### Step 1 — Project Folder Banao

```powershell
mkdir olake-mongodb-pipeline
cd olake-mongodb-pipeline
mkdir data
```

---

### Step 2 — docker-compose.yml Banao

Is file mein **4 services** hain jo ek saath chalti hain.

```yaml
version: "3.9"

services:

  # ✅ Service 1: MongoDB — Source Database (Replica Set required for OLake)
  mongo1:
    image: mongo:6.0
    container_name: primary_mongo
    hostname: mongo1
    command: ["mongod", "--replSet", "rs0", "--bind_ip_all", "--port", "27017"]
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 10s
      retries: 5
      start_period: 40s
    networks:
      - olake-net

  # ✅ Service 2: MongoDB Replica Set Initialize karo
  mongo-init:
    image: mongo:6.0
    container_name: mongo_init
    depends_on:
      mongo1:
        condition: service_healthy
    entrypoint: >
      bash -c "
        mongosh --host mongo1 --username admin --password password
        --authenticationDatabase admin --eval
        'rs.initiate({_id: \"rs0\", members: [{_id: 0, host: \"mongo1:27017\"}]})'
      "
    networks:
      - olake-net
    restart: "no"

  # ✅ Service 3: MinIO — Local S3 Storage (Iceberg files yahan save hongi)
  minio:
    image: minio/minio:RELEASE.2025-04-03T14-56-28Z
    container_name: minio
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"   # S3 API
      - "9001:9001"   # MinIO Web UI
    volumes:
      - ./data/minio-data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - olake-net

  # ✅ Service 4: MinIO Bucket auto-create karo
  mc:
    image: minio/mc:RELEASE.2025-04-03T17-07-56Z
    container_name: mc
    depends_on:
      minio:
        condition: service_healthy
    entrypoint: >
      /bin/sh -c "
        /usr/bin/mc alias set myminio http://minio:9000 minioadmin minioadmin;
        /usr/bin/mc mb myminio/olake-iceberg --ignore-existing;
        echo 'Bucket created!';
        exit 0;
      "
    networks:
      - olake-net
    restart: "no"

networks:
  olake-net:
    driver: bridge
```

**Saari services start karo:**
```powershell
docker compose up -d
```

**Status check karo:**
```powershell
docker ps
```

---

### Step 3 — MongoDB mein Orders Data Daalo

MongoDB shell mein jao:
```powershell
docker exec -it primary_mongo mongosh --username admin --password password --authenticationDatabase admin
```

Ab ye commands run karo:
```javascript
use shop

db.orders.insertMany([
  { order_id: 1, customer: "Rahul Sharma",  product: "Laptop",     amount: 75000, status: "delivered", city: "Delhi" },
  { order_id: 2, customer: "Priya Singh",   product: "Phone",      amount: 25000, status: "pending",   city: "Mumbai" },
  { order_id: 3, customer: "Amit Kumar",    product: "Tablet",     amount: 35000, status: "delivered", city: "Bangalore" },
  { order_id: 4, customer: "Sneha Gupta",   product: "Headphones", amount: 5000,  status: "cancelled", city: "Pune" },
  { order_id: 5, customer: "Rohan Verma",   product: "Monitor",    amount: 18000, status: "delivered", city: "Hyderabad" },
  { order_id: 6, customer: "Neha Joshi",    product: "Keyboard",   amount: 3000,  status: "pending",   city: "Chennai" },
  { order_id: 7, customer: "Vikram Rao",    product: "Mouse",      amount: 1500,  status: "delivered", city: "Kolkata" },
  { order_id: 8, customer: "Pooja Mehta",   product: "Webcam",     amount: 4000,  status: "delivered", city: "Delhi" },
  { order_id: 9, customer: "Arjun Patel",   product: "SSD",        amount: 8000,  status: "pending",   city: "Mumbai" },
  { order_id: 10, customer: "Kavya Reddy",  product: "RAM",        amount: 6000,  status: "delivered", city: "Bangalore" },
  { order_id: 11, customer: "Dev Nair",     product: "CPU",        amount: 22000, status: "cancelled", city: "Pune" },
  { order_id: 12, customer: "Isha Kapoor",  product: "GPU",        amount: 55000, status: "delivered", city: "Delhi" },
  { order_id: 13, customer: "Karan Malhotra", product: "Speaker",  amount: 9000,  status: "pending",   city: "Jaipur" },
  { order_id: 14, customer: "Anjali Das",   product: "Printer",    amount: 12000, status: "delivered", city: "Lucknow" },
  { order_id: 15, customer: "Suresh Iyer",  product: "Router",     amount: 3500,  status: "delivered", city: "Chennai" }
])

// Confirm karo — 15 print hona chahiye
db.orders.countDocuments()
```

Exit karo:
```javascript
exit
```

---

### Step 4 — OLake Config Files Banao

#### `source.json` — MongoDB Connection

```json
{
  "hosts": ["mongo1:27017"],
  "username": "admin",
  "password": "password",
  "authdb": "admin",
  "replica-set": "rs0",
  "read-preference": "secondaryPreferred",
  "srv": false,
  "server-ram": 4,
  "database": "shop",
  "max_threads": 5,
  "backoff_retry_count": 4
}
```

#### `destination.json` — Iceberg + MinIO Destination

```json
{
  "type": "ICEBERG",
  "writer": {
    "catalog_type": "jdbc",
    "jdbc_url": "jdbc:postgresql://iceberg-postgres:5432/iceberg",
    "catalog_name": "olake_iceberg",
    "jdbc_username": "iceberg",
    "jdbc_password": "password",
    "iceberg_s3_path": "s3://olake-iceberg/warehouse",
    "s3_endpoint": "http://minio:9000",
    "s3_use_ssl": false,
    "s3_path_style": true,
    "aws_access_key": "minioadmin",
    "aws_region": "us-east-1",
    "aws_secret_key": "minioadmin"
  }
}
```

> **Note:** Hum Hive Metastore ki jagah JDBC catalog use kar rahe hain (PostgreSQL) — ye easier aur recommended hai local setup ke liye.

---

### Step 5 — OLake: Discover Command (Schema Dhundo)

> **Kya karta hai?** MongoDB mein kaunke collections hain, unka schema kya hai — ye pata karta hai aur `streams.json` file banata hai.

**Windows PowerShell mein:**
```powershell
docker run --pull=always `
  --network olake-mongodb-pipeline_olake-net `
  -v "${PWD}:/mnt/config" `
  olakego/source-mongodb:latest `
  discover `
  --config /mnt/config/source.json
```

**Expected Output:**
```
Discovering streams from MongoDB...
Found collection: shop.orders
streams.json created successfully ✅
```

`streams.json` ab automatically ban jaayegi tumhare folder mein.

---

### Step 6 — streams.json Check Karo aur Edit Karo

Discover ke baad ye file bani hogi. Isme `selected_streams` check karo — `orders` collection select honi chahiye:

```json
{
  "selected_streams": {
    "shop": [
      {
        "stream_name": "orders",
        "partition_regex": "",
        "normalization": false,
        "append_only": false
      }
    ]
  }
}
```

---

### Step 7 — OLake: Sync Command (Data Copy Karo)

> **Kya karta hai?** MongoDB se data uthata hai aur Iceberg format mein MinIO pe save karta hai.

```powershell
docker run --pull=always `
  --network olake-mongodb-pipeline_olake-net `
  -v "${PWD}:/mnt/config" `
  olakego/source-mongodb:latest `
  sync `
  --config /mnt/config/source.json `
  --streams /mnt/config/streams.json `
  --destination /mnt/config/destination.json
```

**Expected Output:**
```
Starting sync for stream: orders
Records synced: 15
Sync completed successfully ✅
Iceberg table created: olake_iceberg.shop.orders
```

---

### Step 8 — MinIO UI se Verify Karo

Browser mein jao: **http://localhost:9001**
- Username: `minioadmin`
- Password: `minioadmin`

`olake-iceberg/warehouse/` folder mein `.parquet` files dikhni chahiye — matlab data successfully sync hua! ✅

---

### Step 9 — Apache Spark se Query Karo

Spark container start karo (docker-compose mein add karo ya directly run karo):

```powershell
docker run -it --rm `
  --network olake-mongodb-pipeline_olake-net `
  -e AWS_ACCESS_KEY_ID=minioadmin `
  -e AWS_SECRET_ACCESS_KEY=minioadmin `
  bitnami/spark:3.5 `
  spark-sql `
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions `
  --conf spark.sql.catalog.olake_iceberg=org.apache.iceberg.spark.SparkCatalog `
  --conf spark.sql.catalog.olake_iceberg.type=jdbc `
  --conf "spark.sql.catalog.olake_iceberg.uri=jdbc:postgresql://iceberg-postgres:5432/iceberg" `
  --conf spark.sql.catalog.olake_iceberg.warehouse=s3://olake-iceberg/warehouse `
  --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 `
  --conf spark.hadoop.fs.s3a.path.style.access=true
```

**Ab SQL queries chalao:**

```sql
-- 1. Saare orders dekho
SELECT * FROM olake_iceberg.shop.orders LIMIT 10;

-- 2. City-wise total sales
SELECT city, COUNT(*) as total_orders, SUM(amount) as total_sales
FROM olake_iceberg.shop.orders
GROUP BY city
ORDER BY total_sales DESC;

-- 3. Status-wise breakdown
SELECT status, COUNT(*) as count
FROM olake_iceberg.shop.orders
GROUP BY status;

-- 4. Sabse expensive order
SELECT customer, product, amount
FROM olake_iceberg.shop.orders
ORDER BY amount DESC
LIMIT 1;
```

---

## 📸 Screenshots

> *(Yahan apne actual screenshots paste karo jab pipeline run karo)*

| Screenshot | Kya Dikhna Chahiye |
|-----------|-------------------|
| `docker ps` output | 4 containers running |
| MongoDB data insert | `{ acknowledged: true, insertedIds: {...} }` |
| OLake discover output | `streams.json` created |
| OLake sync output | `Records synced: 15` |
| MinIO UI | `.parquet` files in bucket |
| Spark SQL result | Orders table data |

---

## ⚠️ Challenges Faced

### 1. MongoDB Replica Set Requirement
**Problem:** OLake CDC ke liye MongoDB ka **replica set mode** zaroori hai — simple standalone MongoDB kaam nahi karta.

**Solution:** `docker-compose.yml` mein `--replSet rs0` flag aur `mongo-init` container add kiya jo automatically replica set initialize karta hai.

---

### 2. Windows mein Docker Volume Paths
**Problem:** Windows mein `${PWD}` Linux jaise kaam nahi karta PowerShell mein.

**Solution:** PowerShell mein backtick (`` ` ``) line continuation use karo aur `${PWD}` ki jagah `$PWD` use karo.

---

### 3. MinIO Bucket Pre-creation
**Problem:** OLake sync fail ho jata tha kyunki MinIO bucket pehle se nahi bani hoti.

**Solution:** `mc` (MinIO Client) container add kiya jo automatically bucket banata hai startup pe.

---

## 💡 Improvements Suggested

| Area | Current | Improvement |
|------|---------|-------------|
| **Sync Mode** | Full Table (har baar poora data) | CDC (Change Data Capture) enable karo — sirf naye/changed records sync hon |
| **Catalog** | JDBC (PostgreSQL) | AWS Glue ya Hive Metastore production ke liye |
| **Monitoring** | Console logs | OLake UI dashboard use karo (localhost:8000) |
| **Schema Evolution** | Manual | OLake automatically naye fields detect karta hai — enable karo |
| **Data Volume** | 15 records | Production mein lakhs of records ke saath test karo |

---

## 🔗 Resources Used

- [OLake GitHub](https://github.com/datazip-inc/olake)
- [OLake Docs — MongoDB Setup](https://olake.io/docs/getting-started/mongodb)
- [OLake Docs — Iceberg JDBC Catalog](https://olake.io/docs/writers/iceberg/catalog/jdbc/)
- [Apache Iceberg Docs](https://iceberg.apache.org/docs/latest/)
- [Apache Spark Docs](https://spark.apache.org/docs/latest/)

---

## 📹 Loom Video

> *(Yahan apna Loom video link paste karo)*

Video mein cover karo:
1. Docker services start karna
2. MongoDB mein data daalna
3. OLake discover + sync run karna
4. MinIO UI mein files verify karna
5. Spark SQL se query karna

---

*Made for Datazip Assignment 1 — MongoDB to Apache Iceberg Pipeline using OLake*
