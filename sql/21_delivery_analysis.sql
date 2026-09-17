-- ============================================================
-- DELIVERY PERFORMANCE AND CUSTOMER SATISFACTION
--
-- Question:
-- Do late deliveries receive worse customer-review scores?
--
-- Scope:
-- Delivered orders with a valid delivery comparison.
-- ============================================================

SELECT
    CASE
        WHEN is_late_delivery = TRUE THEN 'Late delivery'
        ELSE 'On-time delivery'
    END AS delivery_performance,

    COUNT(
        DISTINCT order_id
    ) AS delivered_orders,

    ROUND(
        100.0
        * COUNT(DISTINCT order_id)
        / SUM(COUNT(DISTINCT order_id)) OVER (),
        2
    ) AS order_share_pct,

    COUNT(
        review_score
    ) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        SUM(total_payment_value),
        2
    ) AS delivered_gmv

FROM analytics.fact_orders

WHERE is_delivered = TRUE
  AND is_late_delivery IS NOT NULL

GROUP BY is_late_delivery

ORDER BY is_late_delivery;