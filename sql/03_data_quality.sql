-- 03_data_quality.sql - проверка качества данных
-- Прежде чем считать метрики, проверяем, можно ли доверять данным
-- Выводы записаны под каждым запросом и учитываются в анализе


-- Какой период покрывают данные
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY 1;
-- Вывод: данные с сентября 2016 по октябрь 2018, но в 2016 году и в сентябре–октябре 2018 заказов единицы
-- Анализируем только полные месяцы: январь 2017 - август 2018


-- Какие статусы заказов
SELECT order_status,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY orders DESC;
-- Вывод : 97.02% заказов доставлены (delivered)
-- Выручку считаем только по доставленным заказам, остальное не считаем


-- Заказы без товаров
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status;
-- Вывод: 775 заказов без товаров, почти все unavailable и canceled
-- У доставленных заказов товары есть всегда, это ожидаемо


-- Товары без категории
SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;
-- Вывод: 610 товаров без категории, их оставим как unknown для записи


-- Дубли в отзывах
SELECT COUNT(*) AS duplicated_review_ids
FROM (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS d;
-- Вывод: 789 review_id встречаются больше одного раза


--Количество реальных покупателей
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;
-- Вывод : 99 441 customer_id, но 96 096 уникальных людей
-- customer_id создаётся на каждый заказ, а человека определяет customer_unique_id и покупателей считаем по customer_unique_id


-- ходится ли сумма оплат с ценой товаров + доставкой?
WITH items AS (
    SELECT order_id, SUM(price + freight_value) AS items_total
    FROM order_items
    GROUP BY order_id
),
payments AS (
    SELECT order_id, SUM(payment_value) AS paid_total
    FROM order_payments
    GROUP BY order_id
)
SELECT COUNT(*) AS orders_compared,
       COUNT(*) FILTER (WHERE ABS(i.items_total - p.paid_total) > 1) AS mismatch
FROM items i
JOIN payments p ON p.order_id = i.order_id;
-- Вывод: расхождение больше 1 BRL только у 249 из 98 665 заказов