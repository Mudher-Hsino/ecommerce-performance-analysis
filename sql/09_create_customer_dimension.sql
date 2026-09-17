-- ============================================================
-- CLEANED CUSTOMER DIMENSION
--
-- customer_id:
-- Identifies the customer record attached to a specific order.
--
-- customer_unique_id:
-- Identifies the same shopper across multiple orders and is used
-- for repeat-purchase and customer-value analysis.
-- ============================================================

CREATE OR REPLACE VIEW analytics.dim_customers AS

SELECT
    customer_id,
    customer_unique_id,

    LPAD(
        customer_zip_code_prefix::TEXT,
        5,
        '0'
    ) AS customer_zip_code_prefix,

    INITCAP(
        TRIM(customer_city)
    ) AS customer_city,

    UPPER(
        TRIM(customer_state)
    ) AS customer_state

FROM raw.customers;