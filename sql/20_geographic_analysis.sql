-- ============================================================
-- CUSTOMER-STATE PERFORMANCE
--
-- Scope:
-- Delivered orders only.
--
-- Geography:
-- Customer state represents the destination market where demand
-- and customer payment value originate.
-- ============================================================

WITH state_performance AS (
    SELECT
        c.customer_state,

        SUM(
            o.total_payment_value
        ) AS state_gmv,

        COUNT(
            DISTINCT o.order_id
        ) AS completed_orders,

        COUNT(
            DISTINCT c.customer_unique_id
        ) AS active_customers,

        ROUND(
            SUM(o.total_payment_value)
            / COUNT(DISTINCT o.order_id),
            2
        ) AS average_order_value

    FROM analytics.fact_orders AS o

    INNER JOIN analytics.dim_customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.is_delivered = TRUE

    GROUP BY c.customer_state
)

SELECT
    customer_state,

    ROUND(
        state_gmv,
        2
    ) AS state_gmv,

    completed_orders,
    active_customers,
    average_order_value,

    ROUND(
        100.0
        * state_gmv
        / SUM(state_gmv) OVER (),
        2
    ) AS gmv_share_pct,

    RANK() OVER (
        ORDER BY state_gmv DESC
    ) AS gmv_rank

FROM state_performance

ORDER BY gmv_rank, customer_state;

-- ============================================================
-- ANALYSIS 2: Delivery and satisfaction by customer state
--
-- HAVING excludes very small state samples that could produce
-- unstable percentages.
-- ============================================================

SELECT
    c.customer_state,

    COUNT(
        DISTINCT o.order_id
    ) AS delivered_orders,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * SUM(
            CASE WHEN o.is_late_delivery = TRUE THEN 1 ELSE 0 END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN o.is_late_delivery IS NOT NULL THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(o.review_score),
        2
    ) AS average_review_score,

    ROUND(
        SUM(o.total_payment_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value

FROM analytics.fact_orders AS o

INNER JOIN analytics.dim_customers AS c
    ON o.customer_id = c.customer_id

WHERE o.is_delivered = TRUE

GROUP BY c.customer_state

HAVING COUNT(DISTINCT o.order_id) >= 500

ORDER BY late_delivery_rate_pct DESC;