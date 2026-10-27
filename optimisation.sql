use ecommerce;

-- Before: the function on the column stops MySQL from using an index on it
EXPLAIN
SELECT ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND LEFT(o.order_purchase_timestamp, 7) = '2017-11';

-- Fix: add a composite index, and filter by a date range instead of a function
CREATE INDEX idx_orders_status_ts ON orders (order_status, order_purchase_timestamp);

-- After
EXPLAIN
SELECT ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-11-01'
  AND o.order_purchase_timestamp <  '2017-12-01';