-- 03_aggregation.sql
-- Aggregation and grouped summaries.

-- Aggregation collapses rows.
-- GROUP BY decides the output grain.

-- Basic functions
-- COUNT(*) counts rows.
-- COUNT(column) counts non-NULL values in a column.
-- COUNT(DISTINCT column) counts unique non-NULL values.
-- SUM adds values.
-- AVG averages values.
-- MIN / MAX find lowest and highest values.

-- Pattern: count all rows
-- orders is one row per order, so COUNT(*) counts orders.
SELECT
    COUNT(*) AS order_count
FROM orders;

-- Check: 830 orders.

-- Pattern: count rows per group
-- One row per customer_id, showing how many orders each customer placed.
SELECT
    customer_id,
    COUNT(*) AS num_orders
FROM orders
GROUP BY customer_id
ORDER BY num_orders DESC
LIMIT 10;

-- Check: top result is SAVEA with 31 orders.

-- Common mistakes
-- Counting rows at the wrong grain.
-- Forgetting that aggregation without GROUP BY returns one row.
-- Using COUNT(column) when NULLs matter.
-- Selecting a non-aggregated column that is not in GROUP BY.

-- Memory hooks
-- COUNT(*) = count rows.
-- GROUP BY = choose one row per group.
-- Aggregation changes the output grain.
