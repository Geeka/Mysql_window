use ecommerce;
CREATE OR REPLACE VIEW combined_view AS
SELECT oi.order_id,
       oi.order_item_id,
       oi.product_id,
       oi.price,
       oi.freight_value,
       COALESCE(NULLIF(TRIM(p.product_category_name), ''), 'unknown') AS product_category_name,
       p.product_weight_g,
       o.order_status,
       o.order_purchase_timestamp,
       c.customer_state
FROM order_items oi
JOIN orders    o ON oi.order_id   = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON oi.product_id = p.product_id;

-- Q1
WITH state_cat AS (
    SELECT customer_state, product_category_name, SUM(price) AS revenue
    FROM combined_view
    WHERE order_status = 'delivered'
    GROUP BY customer_state, product_category_name
),
ranked AS (
    SELECT customer_state, product_category_name, revenue,
           RANK() OVER (PARTITION BY customer_state ORDER BY revenue DESC) AS rnk
    FROM state_cat
)
SELECT customer_state, product_category_name, ROUND(revenue, 0) AS revenue, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY customer_state, rnk;

-- Q2
WITH monthly AS (
    SELECT LEFT(order_purchase_timestamp, 7) AS ym,
           SUM(price) AS revenue
    FROM combined_view
    WHERE order_status = 'delivered'
    GROUP BY LEFT(order_purchase_timestamp, 7)
)
SELECT ym,
       ROUND(revenue, 2) AS revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY ym))
                 / LAG(revenue) OVER (ORDER BY ym), 1) AS mom_growth_pct
FROM monthly
ORDER BY ym;

-- Q3
WITH monthly AS (
    SELECT LEFT(order_purchase_timestamp, 7) AS ym,
           SUM(price) AS revenue
    FROM combined_view
    WHERE order_status = 'delivered'
    GROUP BY LEFT(order_purchase_timestamp, 7)
)
SELECT ym,
       ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY ym), 2) AS running_total
FROM monthly
ORDER BY ym;

-- Q4
WITH order_size AS (
    SELECT order_id, MAX(order_item_id) AS items
    FROM combined_view
    WHERE order_status = 'delivered'
    GROUP BY order_id
)
SELECT COUNT(*) AS delivered_orders,
       SUM(items > 1) AS multi_item_orders,
       ROUND(100.0 * SUM(items > 1) / COUNT(*), 1) AS multi_item_pct
FROM order_size;

-- Q5
SELECT product_category_name,
       ROUND(AVG(freight_value), 2) AS avg_freight,
       COUNT(*) AS items
FROM combined_view
WHERE order_status = 'delivered'
GROUP BY product_category_name
HAVING AVG(freight_value) > (
    SELECT AVG(freight_value)
    FROM combined_view
    WHERE order_status = 'delivered'
)
ORDER BY avg_freight DESC;



