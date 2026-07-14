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

-- Pattern: sum a numeric column
-- order_details is one row per product line in an order.
-- SUM(quantity) counts total units sold, not product-line rows.
SELECT
    SUM(quantity) AS total_units_sold
FROM order_details;

-- Check: 51317 total units sold.

-- Pattern: sum per group
-- One row per product_id, showing total units sold per product.
SELECT
    product_id,
    SUM(quantity) AS total_units_sold
FROM order_details
GROUP BY product_id
ORDER BY total_units_sold DESC
LIMIT 10;

-- Check: top product_id is 60 with 1577 units.

-- Pattern: AVG / MIN / MAX
-- products.unit_price is the current/catalogue product price.
SELECT
    AVG(unit_price) AS avg_unit_price,
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price
FROM products;

-- Check: avg = 28.83389609200614, min = 2.5, max = 263.5.

-- Pattern: HAVING
-- WHERE filters rows before grouping. HAVING filters groups after grouping.
-- Customers with more than 20 orders.
SELECT
    customer_id,
    COUNT(*) AS num_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 20
ORDER BY num_orders DESC;

-- Check: SAVEA, ERNSH, and QUICK.

-- Common mistakes
-- Counting rows at the wrong grain.
-- Forgetting that aggregation without GROUP BY returns one row.
-- Using COUNT(column) when NULLs matter.
-- Selecting a non-aggregated column that is not in GROUP BY.
-- Using COUNT(*) when the question asks for total units.
-- Using a descriptive table when the metric lives in a transaction/detail table.
-- Confusing products.unit_price with order_details.unit_price.
-- Using WHERE for a condition on an aggregate.
-- Relying on a SELECT alias inside HAVING.

-- Memory hooks
-- COUNT(*) = count rows.
-- GROUP BY = choose one row per group.
-- Aggregation changes the output grain.
-- WHERE before groups. HAVING after groups.
