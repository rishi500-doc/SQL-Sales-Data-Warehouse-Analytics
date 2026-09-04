/*
===============================================================================
Gold Layer Quality Checks
===============================================================================
Purpose:
    Validate completeness, uniqueness, referential integrity, validity,
    consistency, and candidate fact-grain compliance.

Expectation:
    Detail result sets should return no rows. Summary result sets should return
    zero for every failure count.
===============================================================================
*/

-- ============================================================================
-- 1. Dimension uniqueness and required-key checks
-- ============================================================================
SELECT 'customer_key' AS check_name, customer_key AS key_value, COUNT(*) AS row_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING customer_key IS NULL OR COUNT(*) > 1;

SELECT 'customer_id' AS check_name, customer_id AS key_value, COUNT(*) AS row_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING customer_id IS NULL OR COUNT(*) > 1;

SELECT 'customer_number' AS check_name, customer_number AS key_value, COUNT(*) AS row_count
FROM gold.dim_customers
GROUP BY customer_number
HAVING customer_number IS NULL OR COUNT(*) > 1;

SELECT 'product_key' AS check_name, product_key AS key_value, COUNT(*) AS row_count
FROM gold.dim_products
GROUP BY product_key
HAVING product_key IS NULL OR COUNT(*) > 1;

SELECT 'product_id' AS check_name, product_id AS key_value, COUNT(*) AS row_count
FROM gold.dim_products
GROUP BY product_id
HAVING product_id IS NULL OR COUNT(*) > 1;

SELECT 'product_number' AS check_name, product_number AS key_value, COUNT(*) AS row_count
FROM gold.dim_products
GROUP BY product_number
HAVING product_number IS NULL OR COUNT(*) > 1;

-- ============================================================================
-- 2. Fact completeness and referential integrity
-- ============================================================================
SELECT
    SUM(CASE WHEN order_number IS NULL THEN 1 ELSE 0 END) AS null_order_numbers,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_dates,
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS null_customer_keys,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS null_product_keys
FROM gold.fact_sales
HAVING SUM(CASE WHEN order_number IS NULL THEN 1 ELSE 0 END) > 0
    OR SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) > 0
    OR SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) > 0
    OR SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) > 0;

SELECT
    f.order_number,
    f.customer_key,
    f.product_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL;

-- ============================================================================
-- 3. Candidate fact-grain duplicates
-- ============================================================================
SELECT
    order_number,
    product_key,
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY order_number, product_key, customer_key
HAVING COUNT(*) > 1;

-- ============================================================================
-- 4. Date validity
-- ============================================================================
SELECT
    order_number,
    order_date,
    shipping_date,
    due_date
FROM gold.fact_sales
WHERE shipping_date < order_date
   OR due_date < order_date;

-- ============================================================================
-- 5. Numeric validity and revenue consistency
-- ============================================================================
SELECT
    order_number,
    product_key,
    sales_amount,
    quantity,
    price
FROM gold.fact_sales
WHERE quantity IS NULL OR quantity <= 0
   OR price IS NULL OR price <= 0
   OR sales_amount IS NULL OR sales_amount <= 0;

SELECT
    order_number,
    product_key,
    sales_amount,
    quantity,
    price
FROM gold.fact_sales
WHERE sales_amount IS NOT NULL
  AND quantity IS NOT NULL
  AND price IS NOT NULL
  AND sales_amount <> CONVERT(decimal(19, 4), quantity) * price;

-- ============================================================================
-- 6. Categorical and date validity
-- ============================================================================
SELECT customer_key, marital_status, gender, country
FROM gold.dim_customers
WHERE marital_status IS NULL OR gender IS NULL OR country IS NULL;

SELECT customer_key, marital_status, gender, country
FROM gold.dim_customers
WHERE marital_status NOT IN ('Single', 'Married', 'n/a')
   OR gender NOT IN ('Female', 'Male', 'n/a');

SELECT product_key, category, subcategory, maintenance, product_line, product_cost
FROM gold.dim_products
WHERE category IS NULL OR subcategory IS NULL OR product_line IS NULL
    OR maintenance IS NULL OR product_cost IS NULL OR product_cost < 0
   OR start_date IS NULL;
