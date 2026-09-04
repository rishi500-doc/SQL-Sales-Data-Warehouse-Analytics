/*
===============================================================================
Silver-to-Gold Reconciliation Checks
===============================================================================
Purpose:
    Confirm that the Gold fact view preserves the Silver sales population and
    transformed measures. Gold uses LEFT JOINs, so row-count and measure
    differences identify unexpected loss or duplication during enrichment.

Expectation:
    The comparison should return one row with zero differences.
===============================================================================
*/

SELECT
    silver_row_count,
    gold_row_count,
    gold_row_count - silver_row_count AS row_count_difference,
    silver_quantity_total,
    gold_quantity_total,
    gold_quantity_total - silver_quantity_total AS quantity_difference,
    silver_sales_total,
    gold_sales_total,
    gold_sales_total - silver_sales_total AS sales_difference
FROM (
    SELECT
        COUNT_BIG(*) AS silver_row_count,
        SUM(CONVERT(decimal(19, 4), sls_quantity)) AS silver_quantity_total,
        SUM(CONVERT(decimal(19, 4), sls_sales)) AS silver_sales_total
    FROM silver.crm_sales_details
) s
CROSS JOIN (
    SELECT
        COUNT_BIG(*) AS gold_row_count,
        SUM(CONVERT(decimal(19, 4), quantity)) AS gold_quantity_total,
        SUM(CONVERT(decimal(19, 4), sales_amount)) AS gold_sales_total
    FROM gold.fact_sales
) g;

-- Gold enrichment must not multiply Silver sales rows.
SELECT
    sls_ord_num AS order_number,
    sls_prd_key AS product_number,
    COUNT(*) AS silver_row_count
FROM silver.crm_sales_details
GROUP BY sls_ord_num, sls_prd_key
HAVING COUNT(*) > 1;
