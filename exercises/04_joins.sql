-- 04_joins.sql
-- Combining related tables.

-- Join type decides what rows stay.
-- Table relationship decides whether rows multiply.

-- INNER JOIN: keep matching rows only.
-- LEFT JOIN: keep all rows from the left table, plus matches where they exist.

-- Key Northwind relationships
-- orders.customer_id -> customers.customer_id
-- order_details.order_id -> orders.order_id
-- order_details.product_id -> products.product_id
-- products.category_id -> categories.category_id
-- products.supplier_id -> suppliers.supplier_id

-- Grain reminders
-- orders -> customers: many orders can point to one customer.
-- Joining orders to customers usually keeps one row per order.
--
-- orders -> order_details: one order can have many product lines.
-- Joining orders to order_details changes the grain to one row per order line.
--
-- order_details -> products: many order lines can point to one product.
-- Joining order_details to products usually keeps one row per order line.

-- Validation habit
-- Check row counts before and after joins.
-- Ask: am I adding one matching row, or many matching rows?

-- Pattern: add a lookup/detail column
-- Show orders with the customer company name.
-- Output grain: one row per order.
-- This should not multiply rows because each order points to at most one customer.
SELECT
    orders.order_id,
    orders.order_date,
    orders.customer_id,
    customers.company_name
FROM orders
JOIN customers
    ON orders.customer_id = customers.customer_id
ORDER BY orders.order_id
LIMIT 10;

-- Check: first order_id is 10248 for Vins et alcools Chevalier.

-- Pattern: validate a many-to-one join
-- Base table: orders = 830 rows.
-- Joining orders to customers should stay at 830 rows because each order
-- points to at most one customer.
SELECT
    COUNT(*) AS joined_order_customer_count
FROM orders
JOIN customers
    ON orders.customer_id = customers.customer_id;

-- Check: 830 rows.

-- Pattern: expand one order into its product lines
-- Output grain: one row per product line for order 10248.
-- Rows multiply because one order can have many order_details rows.
SELECT
    o.order_id,
    od.product_id
FROM orders AS o
JOIN order_details AS od
    ON o.order_id = od.order_id
WHERE o.order_id = 10248
ORDER BY od.product_id;

-- Check: 3 rows, for product_id 11, 42 and 72.
-- Both tables contain order_id, so qualify it with the table alias.

-- Pattern: add product names to order lines
-- Output grain: one row per product line for order 10248.
-- Start with order_details because it already has the order filter and quantity.
-- Joining to products is many-to-one, so 3 order lines stay 3 rows.
SELECT
    od.order_id,
    p.product_id,
    p.product_name,
    od.quantity
FROM order_details AS od
JOIN products AS p
    ON p.product_id = od.product_id
WHERE od.order_id = 10248
ORDER BY od.quantity DESC;

-- Check: Queso Cabrales = 12, Singaporean Hokkien Fried Mee = 10,
-- Mozzarella di Giovanni = 5.

-- Pattern: follow a relationship through three tables
-- Show the date, product name and quantity for each line on order 10248.
-- Output grain: one row per product line on the order.
-- Each order_details row matches one order and one product, so neither join
-- multiplies the starting rows.
SELECT
    p.product_name,
    o.order_date,
    od.quantity
FROM order_details AS od
JOIN orders AS o
    ON o.order_id = od.order_id
JOIN products AS p
    ON p.product_id = od.product_id
WHERE od.order_id = 10248
ORDER BY od.quantity DESC;

-- Check: 3 rows dated 1996-07-04, with quantities 12, 10 and 5.

-- Pattern: find rows with no match (anti-join)
-- Find customers who have never placed an order.
-- Output grain: one row per customer with no orders.
-- "All customers" puts customers on the left. A missing order produces NULL
-- in the orders columns, so filter on the right-side primary key.
SELECT
    c.customer_id,
    c.company_name
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Check: 2 rows, PARIS and FISSA.

-- Same pattern: employees who have never handled an order.
SELECT
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees AS e
LEFT JOIN orders AS o
    ON o.employee_id = e.employee_id
WHERE o.order_id IS NULL;

-- Check: 0 rows. Every employee has handled at least one order.
-- An empty result can be the correct answer.

-- Pattern: count matches while keeping rows with zero matches
-- Show every customer and their number of orders, including zero.
-- Output grain after grouping: one row per customer.
SELECT
    c.customer_id,
    c.company_name,
    COUNT(o.order_id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id
ORDER BY order_count, c.customer_id
LIMIT 10;

-- Check: FISSA = 0, PARIS = 0, CENTC = 1.
-- COUNT(o.order_id) ignores the NULL placeholder for customers with no orders.
-- COUNT(*) would incorrectly count that placeholder row as 1.
-- PostgreSQL allows company_name outside GROUP BY because customer_id is its
-- primary key and determines the rest of the customer row.

-- Pattern: filter right-table matches while preserving every left row
-- Show every current employee and their number of orders during 1997.
-- Put the order-date condition in ON so employees with no 1997 match remain.
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    COUNT(o.order_id) AS order_count
FROM employees AS e
LEFT JOIN orders AS o
    ON e.employee_id = o.employee_id
    AND o.order_date >= DATE '1997-01-01'
    AND o.order_date < DATE '1998-01-01'
GROUP BY e.employee_id
ORDER BY order_count, e.last_name;

-- Check: 9 employees. Counts range from Buchanan = 18 to Peacock = 81.
-- The counts sum to 408, matching the total number of orders in 1997.
-- A zero would mean no matching order among current employee records. Proving
-- historical eligibility would require fields such as created_at or hire_date.
--
-- Validation variation: change the ON date range to >= 1996-07-04 and
-- < 1996-07-11. All 9 employees remain, 5 have zero and the counts sum to 6.

-- Pattern: join detail rows, then aggregate to the required grain
-- Show the top 10 customers by net revenue.
-- order_details holds the revenue inputs; orders links each line to a customer;
-- customers supplies the company name.
-- Output grain after grouping: one row per customer.
SELECT
    c.customer_id,
    c.company_name,
    ROUND(
        SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric,
        2
    ) AS net_revenue
FROM order_details AS od
JOIN orders AS o
    ON od.order_id = o.order_id
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY net_revenue DESC
LIMIT 10;

-- Check: QUICK = 110277.31, ERNSH = 104874.98, SAVEA = 104361.95.
-- The joins stay at product-line grain; GROUP BY collapses lines to customers.

-- Same pattern through a different relationship: top categories by revenue.
-- Output grain after grouping: one row per category.
SELECT
    c.category_id,
    c.category_name,
    ROUND(
        SUM(od.quantity * od.unit_price * (1 - od.discount))::numeric,
        2
    ) AS net_revenue
FROM order_details AS od
JOIN products AS p
    ON od.product_id = p.product_id
JOIN categories AS c
    ON p.category_id = c.category_id
GROUP BY c.category_id
ORDER BY net_revenue DESC
LIMIT 5;

-- Check: Beverages = 267868.18, Dairy Products = 234507.28,
-- Confections = 167357.23.
-- category_id -> category_name because category_id is the primary key.
-- category_name -> category_id is not guaranteed, so grouping by name alone
-- does not allow category_id to be selected.

-- Pattern: count at the correct grain after a one-to-many join
-- One order becomes one joined row per product line. Count distinct order IDs
-- when the metric is orders, not product lines.
SELECT
    COUNT(*) AS product_lines,
    COUNT(o.order_id) AS repeated_order_ids,
    COUNT(DISTINCT o.order_id) AS distinct_orders,
    SUM(od.quantity) AS total_units
FROM orders AS o
JOIN order_details AS od
    ON o.order_id = od.order_id
WHERE o.order_id = 10248;

-- Check: 3 product lines, 3 repeated order IDs, 1 order and 27 units.

-- Applied pattern: compare order count with product-line count per customer.
-- customers is not needed because customer_id already exists in orders.
SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(*) AS product_line_count
FROM orders AS o
JOIN order_details AS od
    ON o.order_id = od.order_id
GROUP BY o.customer_id
ORDER BY order_count DESC, o.customer_id
LIMIT 10;

-- Check: SAVEA = 31 orders / 116 lines, ERNSH = 30 / 102,
-- QUICK = 28 / 86.

-- Pattern: do not SUM a parent value after a one-to-many join
-- freight belongs to one order, but it repeats on every joined product line.
SELECT
    o.order_id,
    o.freight,
    COUNT(*) AS product_lines,
    SUM(o.freight) AS inflated_freight
FROM orders AS o
JOIN order_details AS od
    ON o.order_id = od.order_id
WHERE o.order_id = 10248
GROUP BY o.order_id;

-- Check: freight 32.38 repeats across 3 lines, producing the wrong sum 97.14.

-- Safe pattern: if the metric lives in orders, aggregate orders directly.
SELECT
    o.customer_id,
    c.company_name,
    ROUND(SUM(o.freight)::numeric, 2) AS total_freight
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.company_name
ORDER BY total_freight DESC, o.customer_id
LIMIT 5;

-- Check: SAVEA = 6683.70, ERNSH = 6205.39, QUICK = 5605.63.

-- SUM(DISTINCT o.freight) is not a safe fix: separate orders may legitimately
-- have the same freight value and would be collapsed together.

-- Pattern: self-join when one table contains two roles
-- employees.reports_to points to the employee_id of that employee's manager.
-- Output grain: one row per employee.
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    m.first_name AS manager_first_name,
    m.last_name AS manager_last_name
FROM employees AS e
LEFT JOIN employees AS m
    ON e.reports_to = m.employee_id
ORDER BY e.employee_id;

-- Check: Andrew Fuller has no manager; five employees report to Andrew and
-- three report to Steven Buchanan.

-- Memory hooks
-- A join adds columns by matching keys.
-- Join type decides what stays.
-- Relationship decides whether rows multiply.
-- orders -> customers is many-to-one.
-- customers -> orders is one-to-many.
-- Clause pattern: FROM -> JOIN -> ON -> WHERE.
-- If both tables share a column name, qualify it: o.order_id.
-- Start with the table that matches the required output grain.
-- Join only tables needed for selected columns, filters or relationships.
-- INNER JOIN finds matches; LEFT JOIN promises to keep the left table.
-- With INNER JOIN, written table order usually does not change the matches.
-- Logical order: FROM/JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT
-- -> ORDER BY -> LIMIT. PostgreSQL may optimize the physical order.
-- "All X, even without Y" = X LEFT JOIN Y.
-- "X with no Y" = LEFT JOIN Y, then WHERE y.primary_key IS NULL.
-- LEFT JOIN counts including zero = COUNT(right_table.primary_key).
-- COUNT(*) counts rows; COUNT(column) counts non-NULL values.
-- A right-table filter in ON limits matches and preserves left rows.
-- The same filter in WHERE can remove NULL rows and undo the LEFT JOIN.
-- For grouped metrics: join at detail grain, then GROUP BY the required output.
-- GROUP BY the columns that identify what one output row represents.
-- Use a primary key for one row per entity, not for every GROUP BY query.
-- After a one-to-many join, COUNT(parent_id) counts repeated detail rows.
-- COUNT(DISTINCT parent_id) counts the parent entities.
-- Aggregate a metric at the table grain where that metric naturally lives.
-- DISTINCT can fix repeated IDs; it is not a general fix for repeated values.
-- A self-join uses separate aliases when one table plays multiple roles.
