-- ============================================================
-- CUSTOMER PERFORMANCE AND REPEAT-PURCHASE ANALYSIS
--
-- Scope:
-- Delivered orders only.
--
-- customer_unique_id is used because it identifies the same
-- shopper across multiple orders.
-- ============================================================

WITH customer_performance AS (
    SELECT
        c.customer_unique_id,

        COUNT(
            DISTINCT o.order_id
        ) AS completed_orders,

        SUM(
            o.total_payment_value
        ) AS customer_gmv,

        MIN(
            o.order_purchase_date
        ) AS first_purchase_date,

        MAX(
            o.order_purchase_date
        ) AS latest_purchase_date

    FROM analytics.fact_orders AS o

    INNER JOIN analytics.dim_customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.is_delivered = TRUE

    GROUP BY c.customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        completed_orders,
        customer_gmv,
        first_purchase_date,
        latest_purchase_date,

        CASE
            WHEN completed_orders = 1 THEN 'One-time customer'
            ELSE 'Repeat customer'
        END AS customer_segment

    FROM customer_performance
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(
        SUM(customer_gmv),
        2
    ) AS segment_gmv,

    ROUND(
        100.0
        * SUM(customer_gmv)
        / SUM(SUM(customer_gmv)) OVER (),
        2
    ) AS gmv_share_pct,

    ROUND(
        AVG(customer_gmv),
        2
    ) AS average_customer_value,

    ROUND(
        AVG(completed_orders),
        2
    ) AS average_completed_orders

FROM customer_segments

GROUP BY customer_segment

ORDER BY segment_gmv DESC;