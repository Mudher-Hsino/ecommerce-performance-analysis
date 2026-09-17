-- ============================================================
-- EXCEL ORDER-LEVEL EXPORT VIEW
--
-- Grain:
-- One row per order.
--
-- Purpose:
-- Provide a spreadsheet-friendly dataset for PivotTables,
-- formulas, filters and conditional formatting.
-- ============================================================

CREATE OR REPLACE VIEW analytics.excel_orders_export AS

SELECT
    o.order_id,
    o.order_purchase_date,
    o.order_purchase_month,

    EXTRACT(
        YEAR FROM o.order_purchase_date
    )::INTEGER AS order_year,

    EXTRACT(
        MONTH FROM o.order_purchase_date
    )::INTEGER AS order_month_number,

    TO_CHAR(
        o.order_purchase_date,
        'FMMonth'
    ) AS order_month_name,

    o.order_status,
    o.is_delivered,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    cs.customer_segment,

    o.total_payment_value,
    o.item_revenue,
    o.freight_value,
    o.item_count,

    o.primary_payment_type,
    o.maximum_installments,

    o.review_score,
    o.delivery_days,
    o.delivery_variance_days,

    CASE
        WHEN o.is_late_delivery = TRUE
        THEN 'Late delivery'

        WHEN o.is_late_delivery = FALSE
        THEN 'On-time delivery'

        ELSE 'Not applicable'
    END AS delivery_performance

FROM analytics.fact_orders AS o

INNER JOIN analytics.dim_customers AS c
    ON o.customer_id = c.customer_id

LEFT JOIN analytics.customer_summary AS cs
    ON c.customer_unique_id = cs.customer_unique_id;