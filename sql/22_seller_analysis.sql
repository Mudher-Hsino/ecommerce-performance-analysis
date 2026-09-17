-- ============================================================
-- SELLER PERFORMANCE ANALYSIS
--
-- Scope:
-- Delivered orders only.
--
-- Grain of first CTE:
-- One row per seller + order.
--
-- shipped_after_limit identifies whether a seller handed an item
-- to the carrier after the stated shipping deadline.
-- ============================================================

WITH seller_orders AS (
    SELECT
        oi.seller_id,
        oi.order_id,

        SUM(
            oi.item_revenue
        ) AS seller_order_sales,

        BOOL_OR(
            oi.shipped_after_limit = TRUE
        ) AS shipped_after_limit,

        MAX(
            o.review_score
        ) AS review_score

    FROM analytics.fact_order_items AS oi

    INNER JOIN analytics.fact_orders AS o
        ON oi.order_id = o.order_id

    WHERE oi.is_delivered = TRUE

    GROUP BY
        oi.seller_id,
        oi.order_id
),

seller_performance AS (
    SELECT
        seller_id,

        COUNT(*) AS delivered_orders,

        SUM(
            seller_order_sales
        ) AS product_sales,

        ROUND(
            100.0
            * SUM(
                CASE WHEN shipped_after_limit = TRUE THEN 1 ELSE 0 END
            )
            / NULLIF(
                SUM(
                    CASE
                        WHEN shipped_after_limit IS NOT NULL THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS late_shipment_rate_pct,

        ROUND(
            AVG(review_score),
            2
        ) AS average_review_score

    FROM seller_orders

    GROUP BY seller_id

    HAVING COUNT(*) >= 50
)

SELECT
    sp.seller_id,
    s.seller_city,
    s.seller_state,
    sp.delivered_orders,

    ROUND(
        sp.product_sales,
        2
    ) AS product_sales,

    sp.late_shipment_rate_pct,
    sp.average_review_score,

    RANK() OVER (
        ORDER BY sp.product_sales DESC
    ) AS sales_rank

FROM seller_performance AS sp

INNER JOIN analytics.dim_sellers AS s
    ON sp.seller_id = s.seller_id

ORDER BY sales_rank, sp.seller_id;