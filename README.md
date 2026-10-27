# Olist E-commerce SQL Analysis

Five business questions on delivered orders, answered in MySQL 8 with window functions, CTEs, and a subquery.

**Data:** Olist Brazilian E-Commerce dataset (Kaggle), loaded into four tables (`customers`, `orders`, `order_items`, `products`). One view, `combined_view`, joins them. All queries use delivered orders only (96,478 orders).

**How to run:** load the four tables, then run `window_functions.sql` in MySQL 8 or later (it creates the view first). Each query's output is saved as `Q1.csv` to `Q5.csv`.

| # | Question | Technique | Finding |
|---|---|---|---|
| 1 | Which three categories earn the most revenue in each state? | `RANK() OVER (PARTITION BY ...)` | The leader differs by state: cama_mesa_banho leads in SP (472,238) and relogios_presentes leads in RJ (174,895). |
| 2 | How does revenue change month over month? | CTE and `LAG()` | November 2017 revenue was 987,765.37, up 52.4% on October. December fell 26.5%. || 3 | What is the cumulative revenue by month? | `SUM() OVER (ORDER BY ...)` | The running total reaches 13,221,498.11 by August 2018, which equals total delivered revenue. |
| 4 | What share of orders contain more than one item? | CTE | 9,635 of 96,478 delivered orders (10.0%). |
| 5 | Which categories have above-average freight per item? | Subquery in `HAVING` | 32 categories exceed the 19.95 average. The highest are pcs (48.57), eletrodomesticos_2 (44.39), and moveis_colchao_e_estofado (42.74). |

**Notes**
- Early months have very little revenue (2016-09: 134.97, 2016-10: 40,325.11, 2016-12: 10.90, 2017-01: 111,798.36), and November 2016 has no delivered revenue at all, so `LAG()` compares December 2016 with October. Growth percentages
-before 2017 are not meaningful; the November 2017 figure compares adjacent months and is valid.
- Some high-freight categories have small item counts (for example, moveis_colchao_e_estofado has 37 items), so treat their averages with caution.

UPDATE and DELETE (DML): dml_operations.sql runs on a working copy of combined_view, so the source tables are untouched. It relabels 1,603 unknown categories, undoes a deliberately too-broad delete with a savepoint rollback, then removes 2,453 non-delivered rows, leaving 110,197 delivered rows. Each step has a before and after result: DML1.csv to DML10.csv.

Index optimisation: optimisation.sql replaces a LEFT() month filter with a date range and adds a composite index. QOpt_before.csv and QOpt.csv hold the EXPLAIN output: estimated rows read from orders fell from 107,433 (full scan) to 13,166 (index range scan).
