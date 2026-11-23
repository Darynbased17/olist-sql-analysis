-- 04_sales_analysis.sql - анализ продаж
--  считаем только доставленные заказы
--  выручка = сумма цен товаров без доставки, валюта - бразильский реал


-- 1. Сколько заказов и выручки было в каждом месяце?
-- Берём только полные месяцы: январь 2017 - август 2018.
SELECT TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS month,
       COUNT(DISTINCT o.order_id) AS orders,   -- DISTINCT: после JOIN заказ из 3 товаров = 3 строки
       ROUND(SUM(oi.price))       AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY month
ORDER BY month;
-- Вывод: выручка выросла в 7,5 раза — со 112 тыс. в январе 2017 до 839 тыс.
-- в августе 2018. Пик - ноябрь 2017 Черная Пятница : 7 289 заказов и 988 тыс.
-- С начала 2018 года рост остановился: стабильно 6–7 тыс. заказов в месяц
-- Больше заказов не всегда значит больше денег: в мае 2018 заказов на 540, меньше, чем в ноябре 2017, а выручка почти та же - средний чек выше (≈145 против ≈136)


-- 2. Какие категории приносят больше всего выручки? (топ-10)
SELECT t.product_category_name_english AS category,
       ROUND(SUM(oi.price))            AS revenue,
       ROUND(AVG(oi.price), 2)         AS avg_price
FROM order_items oi
JOIN orders o               ON o.order_id = oi.order_id
JOIN products p             ON p.product_id = oi.product_id
JOIN category_translation t ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
-- Вывод: больше всего денег приносят «Красота и здоровье» (1,23 млн), «Часы и подарки» (1,17 млн) и «Товары для дома» (1,02 млн)
-- В топ-10 в основном товары для повседневной жизни, а не дорогая техника.


-- 3. В каких штатах больше всего заказов?
SELECT c.customer_state AS state,
       COUNT(*)         AS orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY state
HAVING COUNT(*) >= 1000 
ORDER BY orders DESC;
-- Вывод: продажи сосредоточены на юго-востоке Бразилии. На штат São Paulo (SP) приходится 42% доставленных заказов (40 501 из 96 478)


-- 4. Как покупатели платят?
SELECT payment_type,
       COUNT(*)                     AS payments,
       ROUND(AVG(payment_value), 2) AS avg_payment
FROM order_payments
GROUP BY payment_type
ORDER BY payments DESC;
-- Вывод: 74% платежей — кредитной картой, 19% — через boleto (бразильская квитанция, которую оплачивают наличными или через онлайн-банк).
-- У кредитной карты самый высокий средний платёж (163), вероятно, потому что по ней можно платить в рассрочку
-- Дорогие покупки делают кредиткой, а не наоборот. Возможность рассрочки важна для дорогих товаров


-- 5. Влияет ли опоздание доставки на оценку покупателя?
SELECT CASE
           WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Опоздал'
           ELSE 'Вовремя'
       END                           AS delivery,
       COUNT(*)                      AS reviews,
       ROUND(AVG(r.review_score), 2) AS avg_score
FROM orders o
JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY delivery;
-- Вывод : 8% заказов доставляются позже обещанного срока
-- (7 700 из 96 361), и их средняя оценка падает с 4,3 («отлично») до 2,6 («плохо»)
-- Чтобы держать высокий рейтинг, нужно улучшать логистику или обещать покупателю более реалистичные сроки доставки