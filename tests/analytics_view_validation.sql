/*
===============================================================================
Analytical View Validation
===============================================================================
Purpose:
    Validate reusable analytics views before exposing them to Power BI.

Expectation:
    The object check should return no missing views. Grain checks should return
    zero failures. Any validation query that returns rows indicates a problem.
    The KPI check is designed to return zero rows when the single-row KPI view is
    valid.

Run after executing the scripts in scripts/data_analysis in dependency order.
===============================================================================
*/

-- 1. Required view deployment check.
WITH required_views AS (
    SELECT view_name
    FROM (VALUES
        ('kpi_summary'),
        ('customer_summary'),
        ('customer_segments'),
        ('product_summary'),
        ('category_summary'),
        ('product_rankings'),
        ('monthly_sales'),
        ('country_summary')
    ) v(view_name)
)
SELECT
    rv.view_name,
    CASE WHEN o.object_id IS NULL THEN 'MISSING' ELSE 'PRESENT' END AS deployment_status
FROM required_views rv
LEFT JOIN sys.objects o
    ON o.schema_id = SCHEMA_ID('analytics')
   AND o.name = rv.view_name
   AND o.type = 'V'
WHERE o.object_id IS NULL
ORDER BY rv.view_name;

-- 2. KPI view must return one row.
SELECT COUNT(*) AS kpi_row_count
FROM analytics.kpi_summary
HAVING COUNT(*) <> 1;

-- 3. Customer summary must be one row per customer key.
SELECT
    customer_key,
    COUNT(*) AS row_count
FROM analytics.customer_summary
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- 4. Customer segmentation must preserve the customer-summary grain.
SELECT
    customer_key,
    COUNT(*) AS row_count
FROM analytics.customer_segments
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- 5. Product summary and ranking must be one row per product key.
SELECT
    product_key,
    COUNT(*) AS row_count
FROM analytics.product_summary
GROUP BY product_key
HAVING COUNT(*) > 1;

SELECT
    product_key,
    COUNT(*) AS row_count
FROM analytics.product_rankings
GROUP BY product_key
HAVING COUNT(*) > 1;

-- 6. Monthly, category, and country outputs must have unique keys.
SELECT
    month_start,
    COUNT(*) AS row_count
FROM analytics.monthly_sales
GROUP BY month_start
HAVING COUNT(*) > 1;

SELECT
    category,
    COUNT(*) AS row_count
FROM analytics.category_summary
GROUP BY category
HAVING COUNT(*) > 1;

SELECT
    country,
    COUNT(*) AS row_count
FROM analytics.country_summary
GROUP BY country
HAVING COUNT(*) > 1;

-- 7. KPI revenue and quantity must reconcile to Gold fact totals.
SELECT
    k.revenue AS analytical_revenue,
    SUM(CONVERT(decimal(19, 4), f.sales_amount)) AS gold_revenue,
    k.quantity AS analytical_quantity,
    SUM(CONVERT(decimal(19, 4), f.quantity)) AS gold_quantity
FROM analytics.kpi_summary k
CROSS JOIN gold.fact_sales f
GROUP BY k.revenue, k.quantity
HAVING k.revenue <> SUM(CONVERT(decimal(19, 4), f.sales_amount))
    OR k.quantity <> SUM(CONVERT(decimal(19, 4), f.quantity));
