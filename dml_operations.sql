SET SQL_SAFE_UPDATES = 0;
DROP TABLE IF EXISTS work_items;
CREATE TABLE work_items AS SELECT * FROM combined_view;

-- 1. UPDATE
SELECT 'before update' AS step, COUNT(*) AS total_rows,
       SUM(product_category_name = 'unknown') AS unknown_rows,
       SUM(product_category_name = 'uncategorized') AS uncategorized_rows
FROM work_items;                                    -- 112,650 | 1,603 | 0
START TRANSACTION;
UPDATE work_items SET product_category_name = 'uncategorized' WHERE product_category_name = 'unknown';
SELECT ROW_COUNT() AS rows_updated;                 -- 1,603
SELECT 'after update' AS step, COUNT(*) AS total_rows,
       SUM(product_category_name = 'unknown') AS unknown_rows,
       SUM(product_category_name = 'uncategorized') AS uncategorized_rows
FROM work_items;                                    -- 112,650 | 0 | 1,603
SAVEPOINT after_update;

-- 2. DELETE (too broad), then undone
SELECT 'before broad delete' AS step, COUNT(*) AS rows_in_table FROM work_items;   -- 112,650
DELETE FROM work_items WHERE price > 0;
SELECT ROW_COUNT() AS rows_deleted;                 -- 112,650
SELECT 'after broad delete' AS step, COUNT(*) AS rows_in_table FROM work_items;    -- 0
ROLLBACK TO SAVEPOINT after_update;
SELECT 'after rollback' AS step, COUNT(*) AS rows_in_table FROM work_items;        -- 112,650

-- 3. DELETE: keep delivered orders only
SELECT 'before delete' AS step, COUNT(*) AS rows_in_table,
       SUM(order_status <> 'delivered') AS non_delivered_rows FROM work_items;     -- 112,650 | 2,453
DELETE FROM work_items WHERE order_status <> 'delivered';
SELECT ROW_COUNT() AS rows_deleted;                 -- 2,453
SELECT 'after delete' AS step, COUNT(*) AS rows_in_table,
       SUM(order_status <> 'delivered') AS non_delivered_rows FROM work_items;     -- 110,197 | 0
COMMIT;