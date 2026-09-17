-- ============================================================
-- ORDER-ITEM FACT VIEW
--
-- Grain:
-- One row per order_id + order_item_id.
--
-- Purpose:
-- 1. Support product, category and seller analysis.
-- 2. Attach purchase dates and order status to each item.
-- 3. Separate product revenue from freight charges.
-- 4. Flag items shipped after their shipping deadline.
-- ============================================================

CREATE OR REPLACE VIEW analytics.fact_order_items AS

SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,

    o.order_status,
    o.order_purchase_timestamp,

    o.order_purchase_timestamp::DATE
        AS order_purchase_date,

    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS order_purchase_month,

    oi.shipping_limit_date,
    o.order_delivered_carrier_date,

    oi.price AS item_revenue,
    oi.freight_value,

    ROUND(
        oi.price + oi.freight_value,
        2
    ) AS item_total_value,

    CASE
        WHEN o.order_status = 'delivered' THEN TRUE
        ELSE FALSE
    END AS is_delivered,

    CASE
        WHEN o.order_delivered_carrier_date IS NULL
          OR oi.shipping_limit_date IS NULL
        THEN NULL

        WHEN o.order_delivered_carrier_date > oi.shipping_limit_date
        THEN TRUE

        ELSE FALSE
    END AS shipped_after_limit

FROM raw.order_items AS oi

INNER JOIN raw.orders AS o
    ON oi.order_id = o.order_id;