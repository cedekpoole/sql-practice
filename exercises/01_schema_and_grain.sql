-- 01_schema_and_grain.sql
-- Schema, grain, and basic row-level queries.

-- Schema = the structure of the database: tables, columns, data types,
-- primary keys, foreign keys, and relationships between tables.
--
-- Grain = what one row represents.

-- Core tables
-- customers: one row per customer/company. PK: customer_id
-- orders: one row per order. PK: order_id
-- order_details: one row per product line in an order. PK: order_id + product_id
-- products: one row per product. PK: product_id

-- Quick checklist
-- 1. What does one row represent?
-- 2. Which table is already at that grain?
-- 3. Which columns do I need?
-- 4. Do I need a filter, sort, limit, or metric?
-- 5. How can I check the result?

-- Pattern: preview rows
-- LIMIT gives a sample; it does not change the table grain.
SELECT
    product_id,
    product_name,
    unit_price,
    units_in_stock,
    discontinued
FROM products
LIMIT 10;

-- Pattern: filter rows
-- WHERE chooses rows.
SELECT
    customer_id,
    company_name,
    country
FROM customers
WHERE country = 'UK';

-- Pattern: filter then sort
-- ORDER BY arranges the rows returned.
SELECT
    customer_id,
    company_name,
    country
FROM customers
WHERE country = 'UK'
ORDER BY company_name;

-- Expected check for the UK customer query:
-- 7 rows, all country = 'UK', sorted by company_name.

-- Pattern: numeric filter
-- Numeric values do not need quotes.
SELECT
    product_id,
    product_name,
    unit_price
FROM products
WHERE unit_price > 50;

-- Expected check:
-- 7 rows, all unit_price values above 50.

-- Pattern: date filter
-- Date values use quotes. Match the wording to the right date column.
-- placed = order_date; needed by = required_date; shipped = shipped_date.
SELECT
    order_id,
    customer_id,
    order_date,
    required_date,
    shipped_date
FROM orders
WHERE order_date >= '1998-01-01'
ORDER BY order_date
LIMIT 10;

-- Expected check:
-- All order_date values are on or after 1998-01-01.

-- Useful reminders
-- SELECT chooses columns.
-- FROM chooses the table.
-- WHERE filters rows.
-- ORDER BY sorts rows.
-- LIMIT restricts how many rows are shown.
-- Text and dates use quotes. Numbers do not.

-- Common mistakes
-- SELECT * when only a few columns are needed.
-- Forgetting quotes around text values: country = 'UK'
-- Putting quotes around numbers by habit: unit_price > 50
-- Filtering on the wrong date column.
-- Thinking LIMIT means the table only has that many rows.
