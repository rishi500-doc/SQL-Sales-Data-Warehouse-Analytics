# SQL Data Analysis Layer

This folder contains standalone SQL analyses and reports built from the
existing Gold views.

## Analysis Scripts

1. `01_change_over_time_analysis.sql`
2. `02_cumulative_analysis.sql`
3. `03_performance_analysis.sql`
4. `04_data_segmentation.sql`
5. `05_part_to_whole_analysis.sql`
6. `06_report_customers.sql`
7. `07_report_products.sql`
8. `08_country_analysis.sql`

## Execution Order

Run the files in numeric order in SSMS after deploying the Gold views:

```text
01_change_over_time_analysis.sql
02_cumulative_analysis.sql
03_performance_analysis.sql
04_data_segmentation.sql
05_part_to_whole_analysis.sql
06_report_customers.sql
07_report_products.sql
08_country_analysis.sql
```

The report scripts create `gold.report_customers` and `gold.report_products`.
