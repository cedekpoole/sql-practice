-- 02_filtering_and_nulls.sql
-- Filtering rows with WHERE, ORDER BY, LIMIT, and NULL checks.

-- WHERE filters rows.
-- ORDER BY sorts rows.
-- LIMIT restricts how many rows are shown.
-- Text and dates use quotes. Numbers do not.
-- NULL means missing/unknown; use IS NULL or IS NOT NULL.

-- Pattern: text filter
SELECT
    customer_id,
    company_name,
    country
FROM customers
WHERE country = 'UK';

-- Check: 7 rows, all country = 'UK'.

-- Pattern: filter then sort
SELECT
    customer_id,
    company_name,
    country
FROM customers
WHERE country = 'UK'
ORDER BY company_name;

-- Check: 7 rows, sorted by company_name.

-- Pattern: numeric filter
SELECT
    product_id,
    product_name,
    unit_price
FROM products
WHERE unit_price > 50;

-- Check: 7 rows, all unit_price values above 50.

-- Pattern: date filter
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

-- Check: all order_date values are on or after 1998-01-01.

-- Pattern: NULL filter
-- Scenario: customers without a region recorded.
-- Write and run this one during practice.

-- Pattern: combine AND / OR with parentheses
-- Scenario: active products that are expensive or low in stock.
-- active = discontinued = 0
-- expensive = unit_price >= 50
-- low stock = units_in_stock <= reorder_level
SELECT
    product_id,
    product_name,
    unit_price,
    units_in_stock,
    reorder_level,
    discontinued
FROM products
WHERE discontinued = 0
  AND (
      unit_price >= 50
      OR units_in_stock <= reorder_level
  );

-- Check: 22 rows. Every row has discontinued = 0.
-- Each row should satisfy either unit_price >= 50 or units_in_stock <= reorder_level.

-- Common mistakes
-- WHERE region = NULL
-- Forgetting quotes around text/date values.
-- Filtering on shipped_date when the question says "placed".
-- Missing parentheses when mixing AND and OR.
-- Thinking LIMIT means the table only has that many rows.
