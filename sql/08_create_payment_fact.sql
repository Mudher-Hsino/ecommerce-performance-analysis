-- ============================================================
-- CLEANED ORDER-PAYMENT FACT VIEW
--
-- Purpose:
-- 1. Consolidate multiple payment records into one row per order.
-- 2. Calculate the total amount paid.
-- 3. Identify the highest-value payment method as the primary one.
-- 4. Retain counts for auditing payment anomalies.
-- ============================================================

CREATE OR REPLACE VIEW analytics.fact_order_payments AS

WITH ranked_payments AS (
    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                payment_value DESC,
                payment_sequential ASC
        ) AS payment_rank

    FROM raw.order_payments
)

SELECT
    order_id,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value,

    COUNT(*) AS payment_record_count,

    COUNT(
        DISTINCT payment_type
    ) AS payment_method_count,

    MAX(
        payment_installments
    ) AS maximum_installments,

    MAX(
        CASE
            WHEN payment_rank = 1 THEN payment_type
            ELSE NULL
        END
    ) AS primary_payment_type,

    SUM(
        CASE
            WHEN payment_value = 0 THEN 1
            ELSE 0
        END
    ) AS zero_value_payment_records

FROM ranked_payments

GROUP BY order_id;