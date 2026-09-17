-- ============================================================
-- EXECUTIVE KPI AND REVENUE ANALYSIS
--
-- Financial definitions:
--
-- Delivered GMV:
-- Total customer payment value for delivered orders.
-- Includes product prices and freight.
--
-- Product sales:
-- Item price only, excluding freight.
-- Used for product and category performance.
--
-- These values represent marketplace transaction value,
-- not Olist's net company profit.
-- ============================================================


-- ------------------------------------------------------------
-- ANALYSIS 1: Reconcile payment value with item-level value
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        SUM(total_payment_value),
        2
    ) AS delivered_payment_value,

    ROUND(
        SUM(item_revenue),
        2
    ) AS delivered_product_sales,

    ROUND(
        SUM(freight_value),
        2
    ) AS delivered_freight_value,

    ROUND(
        SUM(item_total_value),
        2
    ) AS delivered_item_plus_freight,

    ROUND(
        SUM(total_payment_value)
        - SUM(item_total_value),
        2
    ) AS payment_reconciliation_difference

FROM analytics.fact_orders

WHERE is_delivered = TRUE;

-- ------------------------------------------------------------
-- ANALYSIS 2: Headline executive KPIs
--
-- Scope:
-- Delivered orders only.
-- ------------------------------------------------------------

WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.total_payment_value,
        o.review_score,
        o.is_late_delivery

    FROM analytics.fact_orders AS o

    INNER JOIN analytics.dim_customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.is_delivered = TRUE
)

SELECT
    ROUND(
        SUM(total_payment_value),
        2
    ) AS delivered_gmv,

    COUNT(
        DISTINCT order_id
    ) AS completed_orders,

    COUNT(
        DISTINCT customer_unique_id
    ) AS active_customers,

    ROUND(
        SUM(total_payment_value)
        / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    ROUND(
        100.0
        * SUM(
            CASE WHEN is_late_delivery = TRUE THEN 1 ELSE 0 END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN is_late_delivery IS NOT NULL THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_delivery_rate_pct

FROM delivered_orders;