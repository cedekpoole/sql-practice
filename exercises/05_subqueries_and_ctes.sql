-- 05_subqueries_and_ctes.sql
-- Breaking a calculation into stages.

-- A CTE (common table expression) is a named query result.
-- The query inside AS (...) produces rows.
-- The outer query can use those rows through the CTE name.
-- The result is not stored and stops existing at the final semicolon.
--
-- Pattern:
-- WITH result_name AS (
--     first query
-- )
-- SELECT ...
-- FROM result_name;

-- Use a CTE when the answer requires calculations at different grains.
-- Example: average order value requires:
--   1. one total per order
--   2. the average of those order totals

-- Pattern: aggregate, then aggregate again
-- Source grain: one row per product line per order.
-- CTE grain: one row per order.
-- Final grain: one row overall.
WITH order_totals AS (
    SELECT
        order_id,
        SUM(unit_price * quantity * (1 - discount)) AS order_total
    FROM order_details
    GROUP BY order_id
)
SELECT
    ROUND(AVG(order_total)::numeric, 2) AS average_order_value
FROM order_totals;

-- Check: average_order_value = 1525.05.

-- AVG(unit_price * quantity * (1 - discount)) would be wrong here.
-- It would calculate the average product-line value, not average order value.

-- Inspect the intermediate result when the grain change is unclear.
SELECT
    order_id,
    ROUND(
        SUM(unit_price * quantity * (1 - discount))::numeric,
        2
    ) AS order_total
FROM order_details
GROUP BY order_id
ORDER BY order_id
LIMIT 10;

-- Check: order 10248 has three product lines but one order total of 440.00.

-- Pattern: average units per order
-- SUM(quantity) first gives one unit total per order.
-- AVG(unit_total) then averages orders rather than product lines.
WITH unit_totals AS (
    SELECT
        order_id,
        SUM(quantity) AS unit_total
    FROM order_details
    GROUP BY order_id
)
SELECT
    ROUND(AVG(unit_total)::numeric, 2) AS avg_order_units
FROM unit_totals;

-- Check: avg_order_units = 61.83.

-- A subquery is a query inside another query.
-- A scalar subquery returns one value: one row and one column.

-- Pattern: compare rows with a calculated benchmark
-- The inner query returns the overall average product price.
-- The outer query compares each product with that one value.
SELECT
    product_id,
    product_name,
    unit_price
FROM products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM products
)
ORDER BY unit_price DESC;

-- Check: 25 products cost more than the overall average of 28.833896....

-- Pattern: products below the overall average stock level
SELECT
    product_id,
    product_name,
    units_in_stock
FROM products
WHERE units_in_stock < (
    SELECT AVG(units_in_stock)
    FROM products
)
ORDER BY units_in_stock
LIMIT 10;

-- LIMIT 10 keeps the CLI preview short.
-- Remove it when the requested answer must include every matching product.

-- Memory hooks
-- A CTE names the middle step so the next query can use its rows.
-- "Average order value" = make one row per order before taking AVG.
-- A comparison such as > or < needs one value; a scalar subquery can calculate it.
-- Benchmark inside the parentheses; test each outer row against it.
