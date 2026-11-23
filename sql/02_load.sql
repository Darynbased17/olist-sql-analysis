-- 02_load.sql — загрузка CSV в таблицы и создание индексов
-- Порядок загрузки важен: сначала справочники, потом orders,
-- потом таблицы, которые ссылаются на orders (иначе не пустят FOREIGN KEY)

\copy category_translation FROM 'C:/projects/olist-sql-analysis/data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy customers      FROM 'C:/projects/olist-sql-analysis/data/olist_customers_dataset.csv'      WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy sellers        FROM 'C:/projects/olist-sql-analysis/data/olist_sellers_dataset.csv'        WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy products       FROM 'C:/projects/olist-sql-analysis/data/olist_products_dataset.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy orders         FROM 'C:/projects/olist-sql-analysis/data/olist_orders_dataset.csv'         WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_items    FROM 'C:/projects/olist-sql-analysis/data/olist_order_items_dataset.csv'    WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_payments FROM 'C:/projects/olist-sql-analysis/data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_reviews  FROM 'C:/projects/olist-sql-analysis/data/olist_order_reviews_dataset.csv'  WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Индексы ускоряют JOIN и фильтры по этим колонкам
-- IF NOT EXISTS — чтобы скрипт не падал при повторном запуске
CREATE INDEX IF NOT EXISTS idx_customers_unique   ON customers (customer_unique_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer    ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts ON orders (order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_items_product      ON order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_items_seller       ON order_items (seller_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order      ON order_reviews (order_id);

ANALYZE;  -- обновляет статистику, чтобы PostgreSQL выбирал быстрые планы запросов

-- Проверка: сколько строк загрузилось

SELECT 'customers' AS table_name, COUNT(*) AS rows FROM customers
UNION ALL SELECT 'sellers',        COUNT(*) FROM sellers
UNION ALL SELECT 'products',       COUNT(*) FROM products
UNION ALL SELECT 'orders',         COUNT(*) FROM orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM order_reviews
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;
-- Ожидаемый результат: orders 99 441, order_items 112 650, order_reviews 99 224