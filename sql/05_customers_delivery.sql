-- 05_customers_delivery.sql - почему покупатели не возвращаются?
-- Покупателя считаем по customer_unique_id 


-- 1. Сколько раз покупатели возвращаются?
SELECT orders_count,
       COUNT(*) AS customers
FROM (
    SELECT c.customer_unique_id,
           COUNT(*) AS orders_count
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS t
GROUP BY orders_count
ORDER BY orders_count;
-- Вывод: из 93 358 покупателей с доставленными заказами 90 557 (97%) купили только один раз
-- Повторно покупают лишь 3% - магазин почти не удерживает клиентов, и весь рост идёт за счёт новых


-- 2. Топ-10 покупателей по сумме покупок
SELECT c.customer_unique_id,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price))       AS spent
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY spent DESC
LIMIT 10;
-- Вывод: 9 из 10 самых ценных покупателей сделали всего один заказ
-- Постоянных VIP-клиентов у магазина нет : даже те, кто тратит много, больше не возвращаются


-- 3. Сколько ждут доставку в разных штатах и как часто она опаздывает?
SELECT c.customer_state AS state,
       COUNT(*)         AS orders,
       ROUND(AVG(o.order_delivered_customer_date::date
               - o.order_purchase_timestamp::date), 1) AS avg_delivery_days,
       ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                              THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY state
HAVING COUNT(*) >= 500
ORDER BY avg_delivery_days DESC;
-- Вывод: в São Paulo заказ едет в среднем 8,7 дня и опаздывает в 6% случаев.
-- На севере и северо-востоке (PA, MA, CE) доставка идёт 21–24 дня - в 2,5-2,7 раза дольше, а опаздывает до 20% заказов (MA)


