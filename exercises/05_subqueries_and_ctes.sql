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

-- A list subquery returns one column and can return many rows.
-- IN tests whether an outer value appears anywhere in that list.
-- Repeated values in the inner result do not duplicate outer rows.

-- Pattern: products supplied by suppliers based in the UK
-- Inner result: the list of UK supplier IDs.
-- Outer grain: one row per matching product.
SELECT
    product_id,
    product_name,
    supplier_id
FROM products
WHERE supplier_id IN (
    SELECT supplier_id
    FROM suppliers
    WHERE country = 'UK'
)
ORDER BY product_id
LIMIT 10;

-- Check: 7 products supplied by supplier IDs 1 and 8.
-- Use a JOIN when columns from suppliers are needed in the result.
-- Use IN when suppliers are only being used as a membership filter.

-- EXISTS is true when its subquery finds at least one row.
-- A correlated subquery refers to the current row of the outer query.
-- SELECT 1 is a placeholder because EXISTS only checks whether a row exists.

-- Pattern: suppliers with at least one discontinued product
-- Outer grain: one row per supplier.
-- Products provide evidence but are not added to the result.
SELECT
    s.supplier_id,
    s.company_name
FROM suppliers AS s
WHERE EXISTS (
    SELECT 1
    FROM products AS p
    WHERE p.supplier_id = s.supplier_id
      AND p.discontinued = 1
)
ORDER BY s.supplier_id
LIMIT 10;

-- Check: 9 suppliers qualify.

-- NOT EXISTS is true when its subquery finds no matching rows.

-- Pattern: employees with no orders during a date range
-- Outer grain: one row per employee.
-- Conditions inside the subquery define which orders count as matches.
SELECT
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.employee_id = e.employee_id
      AND o.order_date >= DATE '1996-07-04'
      AND o.order_date < DATE '1996-07-11'
)
ORDER BY e.employee_id;

-- Check: employee IDs 1, 2, 7, 8 and 9 had no orders in the period.
-- Prefer NOT EXISTS when only unmatched rows are needed.
-- Use LEFT JOIN when all left rows must remain, including matched rows.

-- Pattern: compare each row with its own group's benchmark
-- The inner query refers to p.category_id from the current outer row.
-- This makes the average change according to the product's category.
SELECT
    p.product_id,
    p.product_name,
    p.category_id,
    p.unit_price
FROM products AS p
WHERE p.unit_price < (
    SELECT AVG(p2.unit_price)
    FROM products AS p2
    WHERE p2.category_id = p.category_id
)
ORDER BY p.unit_price, p.product_id
LIMIT 10;

-- Check: product 33 is first at 2.50.
-- Its category average is approximately 28.73.
-- Without the inner WHERE, every product would use the overall average.

-- Pattern: compare each group's metric with an overall benchmark
-- WHERE filters individual products before grouping.
-- HAVING filters categories after their averages have been calculated.
SELECT
    category_id,
    AVG(unit_price) AS category_avg
FROM products
GROUP BY category_id
HAVING AVG(unit_price) > (
    SELECT AVG(unit_price)
    FROM products
)
ORDER BY category_avg DESC;

-- Check: category IDs 6, 1 and 7 qualify.
-- PostgreSQL accepts category_avg in ORDER BY, but not in HAVING.

-- Memory hooks
-- A CTE names the middle step so the next query can use its rows.
-- "Average order value" = make one row per order before taking AVG.
-- A comparison such as > or < needs one value; a scalar subquery can calculate it.
-- Benchmark inside the parentheses; test each outer row against it.
-- No outer reference = one benchmark for every row.
-- Outer reference = the benchmark changes with the current outer row.
-- IN: build the allowed-value list inside; filter the outer rows with it.
-- EXISTS: for this outer row, can the inner query find one match?
-- NOT EXISTS: keep the outer row only when no match can be found.
-- Filter source rows with WHERE; filter calculated groups with HAVING.
