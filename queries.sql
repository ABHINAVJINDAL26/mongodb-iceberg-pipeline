SHOW TABLES IN olake_iceberg.shop;
SELECT * FROM olake_iceberg.shop.orders;
SELECT city, COUNT(*) as orders, SUM(amount) as total_sales FROM olake_iceberg.shop.orders GROUP BY city ORDER BY total_sales DESC;
SELECT status, COUNT(*) as count FROM olake_iceberg.shop.orders GROUP BY status;
