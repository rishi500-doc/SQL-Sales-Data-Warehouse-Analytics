/*
===============================================================================
Gold Business Rules
===============================================================================
Purpose:
    Evaluate business-rule compliance in the Gold sales model. Each query
    returns only failed rows so the output can be investigated directly.
===============================================================================
*/

-- Shipping and due dates cannot precede the order date.
SELECT
    order_number,
    order_date,
    shipping_date,
    due_date
FROM gold.fact_sales
WHERE shipping_date < order_date
   OR due_date < order_date;

-- Revenue must reconcile to quantity multiplied by selling price.
SELECT
    order_number,
    product_key,
    quantity,
    price,
    sales_amount,
    CONVERT(decimal(19, 4), quantity) * price AS expected_sales_amount
FROM gold.fact_sales
WHERE quantity IS NOT NULL
  AND price IS NOT NULL
  AND sales_amount IS NOT NULL
  AND sales_amount <> CONVERT(decimal(19, 4), quantity) * price;

-- Current product cost cannot be negative.
SELECT
    product_key,
    product_number,
    product_cost
FROM gold.dim_products
WHERE product_cost < 0;

-- Customer ages must be plausible as of the current date.
SELECT
    customer_key,
    birthdate,
    DATEDIFF(YEAR, birthdate, CAST(GETDATE() AS date))
        - CASE
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, birthdate, CAST(GETDATE() AS date)), birthdate)
                 > CAST(GETDATE() AS date) THEN 1
            ELSE 0
          END AS age_years
FROM gold.dim_customers
WHERE birthdate > CAST(GETDATE() AS date)
   OR birthdate < DATEADD(YEAR, -120, CAST(GETDATE() AS date));
