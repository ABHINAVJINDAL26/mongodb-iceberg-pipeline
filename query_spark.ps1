docker run -it --rm `
  --network datazip_ass1mongodb_olake-net `
  -v "$PWD`:/mnt/config" `
  -e AWS_ACCESS_KEY_ID=minioadmin `
  -e AWS_SECRET_ACCESS_KEY=minioadmin `
  -e AWS_REGION=us-east-1 `
  -u root `
  --hostname localhost `
  apache/spark:3.5.0 `
  /opt/spark/bin/spark-sql `
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.3,org.apache.hadoop:hadoop-aws:3.3.4,software.amazon.awssdk:bundle:2.20.18,org.postgresql:postgresql:42.6.0 `
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions `
  --conf spark.sql.catalog.olake_iceberg=org.apache.iceberg.spark.SparkCatalog `
  --conf spark.sql.catalog.olake_iceberg.catalog-impl=org.apache.iceberg.jdbc.JdbcCatalog `
  --conf spark.sql.catalog.olake_iceberg.uri=jdbc:postgresql://iceberg-postgres:5432/iceberg `
  --conf spark.sql.catalog.olake_iceberg.jdbc.user=iceberg `
  --conf spark.sql.catalog.olake_iceberg.jdbc.password=password `
  --conf spark.sql.catalog.olake_iceberg.warehouse=s3://olake-iceberg/warehouse `
  --conf spark.sql.catalog.olake_iceberg.io-impl=org.apache.iceberg.aws.s3.S3FileIO `
  --conf spark.sql.catalog.olake_iceberg.s3.endpoint=http://minio:9000 `
  --conf spark.sql.catalog.olake_iceberg.s3.path-style-access=true `
  --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 `
  --conf spark.hadoop.fs.s3a.access.key=minioadmin `
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin `
  --conf spark.hadoop.fs.s3a.path.style.access=true `
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem `
  --conf spark.driver.bindAddress=127.0.0.1 `
  --conf spark.driver.host=127.0.0.1
