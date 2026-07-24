-- 05_subqueries_and_ctes.sql
-- Breaking a calculation into stages.

-- A CTE (common table expression) is a named query result.
-- It exists only while the full query runs.
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

-- Memory hooks
-- "Average of totals" = calculate each total first, then average.
-- Each query stage can have a different grain.
-- Check the output grain of the CTE before using it.
-- A CTE makes an intermediate result readable; it does not store a table.
