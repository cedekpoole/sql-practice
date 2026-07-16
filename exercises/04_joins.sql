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

-- Memory hooks
-- A join adds columns by matching keys.
-- Join type decides what stays.
-- Relationship decides whether rows multiply.
-- orders -> customers is many-to-one.
-- customers -> orders is one-to-many.
