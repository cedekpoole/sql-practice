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
-- "All X, even without Y" = X LEFT JOIN Y.
-- "X with no Y" = LEFT JOIN Y, then WHERE y.primary_key IS NULL.
