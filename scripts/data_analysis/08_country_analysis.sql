/*
===============================================================================
Country-Based Analysis
===============================================================================
Purpose:
    - To compare sales performance across customer countries.
    - To identify the largest markets by revenue, orders, and customers.
    - To support geographic reporting and market prioritization.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), COUNT(DISTINCT)
    - Window Functions: SUM() OVER()
===============================================================================
*/

WITH country_sales AS (
    SELECT
        COALESCE(c.country, 'Unknown') AS country,
        SUM(f.sales_amount) AS total_sales,
        COUNT(DISTINCT f.order_number) AS total_orders,
        COUNT(DISTINCT f.customer_key) AS total_customers,
        SUM(f.quantity) AS total_quantity
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY COALESCE(c.country, 'Unknown')
)
SELECT
    country,
    total_sales,
    total_orders,
    total_customers,
    total_quantity,
    total_sales / NULLIF(total_orders, 0) AS average_order_value,
    ROUND(
        CAST(total_sales AS float) / NULLIF(SUM(total_sales) OVER (), 0) * 100,
        2
    ) AS percentage_of_total_sales
FROM country_sales
ORDER BY total_sales DESC;
