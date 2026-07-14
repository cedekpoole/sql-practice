-- 01_schema_and_grain.sql
-- Schema and table grain.

-- Schema = database structure: tables, columns, data types, keys, relationships.
-- Grain = what one row represents.
-- Primary key = column(s) that uniquely identify one row.
-- Foreign key = column that points to a row in another table.

-- Inspect in psql
-- \dt              -- list tables
-- \d customers     -- describe one table

-- Core Northwind tables
-- customers: one row per customer/company. PK: customer_id
-- orders: one row per order. PK: order_id
-- order_details: one row per product line in an order. PK: order_id + product_id
-- products: one row per product. PK: product_id

-- Key relationships
-- orders.customer_id -> customers.customer_id
-- order_details.order_id -> orders.order_id
-- order_details.product_id -> products.product_id
-- products.category_id -> categories.category_id
-- products.supplier_id -> suppliers.supplier_id

-- Grain checklist
-- 1. What does one source row represent?
-- 2. What should one output row represent?
-- 3. Which table is already closest to that output grain?
-- 4. Will the query keep the same grain or collapse/change it?

-- Pattern: preview a table without SELECT *
SELECT
    product_id,
    product_name,
    unit_price,
    units_in_stock,
    discontinued
FROM products
LIMIT 10;

-- Output grain examples
-- SELECT rows from customers -> one row per customer/company.
-- SELECT rows from orders -> one row per order.
-- SELECT rows from order_details -> one row per product line in an order.
-- SELECT rows from products -> one row per product.

-- Common mistakes
-- Confusing selected columns with grain.
-- Using SELECT * instead of choosing useful columns.
-- Forgetting that order_details is not one row per order.
-- Assuming an ID alone explains the record without checking the table grain.

-- Memory hooks
-- Grain = what one row means.
-- The primary key usually reveals the grain.
-- Start from the table that already matches the question.
