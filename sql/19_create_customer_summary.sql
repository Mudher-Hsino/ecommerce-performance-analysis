-- ============================================================
-- CUSTOMER SUMMARY AND SEGMENTATION VIEW
--
-- Grain:
-- One row per customer_unique_id.
--
-- Segmentation:
-- Customers are divided into value quartiles using NTILE(4).
-- Quartile 4 contains the highest-value 25% of customers.
-- ============================================================

CREATE OR REPLACE VIEW analytics.customer_summary AS

WITH customer_performance AS (
    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT o.order_id
        ) AS completed_orders,

        ROUND(
            SUM(o.total_payment_value),
            2
        ) AS customer_gmv,

        ROUND(
            SUM(o.total_payment_value)
            / COUNT(DISTINCT o.order_id),
            2
        ) AS customer_average_order_value,

        MIN(
            o.order_purchase_date
        ) AS first_purchase_date,

        MAX(
            o.order_purchase_date
        ) AS latest_purchase_date

    FROM analytics.fact_orders AS o

    INNER JOIN raw.customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.is_delivered = TRUE

    GROUP BY c.customer_unique_id
),

customer_scoring AS (
    SELECT
        customer_unique_id,
        completed_orders,
        customer_gmv,
        customer_average_order_value,
        first_purchase_date,
        latest_purchase_date,

        latest_purchase_date - first_purchase_date
            AS customer_lifespan_days,

        NTILE(4) OVER (
            ORDER BY customer_gmv
        ) AS value_quartile

    FROM customer_performance
)

SELECT
    customer_unique_id,
    completed_orders,
    customer_gmv,
    customer_average_order_value,
    first_purchase_date,
    latest_purchase_date,
    customer_lifespan_days,
    value_quartile,

    CASE
        WHEN completed_orders > 1
         AND value_quartile = 4
        THEN 'VIP repeat customer'

        WHEN completed_orders > 1
        THEN 'Repeat customer'

        WHEN completed_orders = 1
         AND value_quartile = 4
        THEN 'High-value one-time customer'

        ELSE 'Standard one-time customer'
    END AS customer_segment

FROM customer_scoring;