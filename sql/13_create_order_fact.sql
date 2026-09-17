-- ============================================================
-- CENTRAL ORDER FACT VIEW
--
-- Grain:
-- One row per order_id.
--
-- Purpose:
-- 1. Preserve every order.
-- 2. Aggregate item-level information to order level.
-- 3. Attach consolidated payments and cleaned reviews.
-- 4. Calculate delivery-performance measures.
-- 5. Prevent many-to-many join duplication.
-- ============================================================

CREATE OR REPLACE VIEW analytics.fact_orders AS

WITH order_item_summary AS (
    SELECT
        order_id,

        COUNT(*) AS item_count,

        COUNT(DISTINCT product_id)
            AS distinct_product_count,

        COUNT(DISTINCT seller_id)
            AS seller_count,

        ROUND(SUM(item_revenue), 2)
            AS item_revenue,

        ROUND(SUM(freight_value), 2)
            AS freight_value,

        ROUND(SUM(item_total_value), 2)
            AS item_total_value

    FROM analytics.fact_order_items

    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,

    o.order_purchase_timestamp::DATE
        AS order_purchase_date,

    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS order_purchase_month,

    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(i.item_count, 0)
        AS item_count,

    COALESCE(i.distinct_product_count, 0)
        AS distinct_product_count,

    COALESCE(i.seller_count, 0)
        AS seller_count,

    COALESCE(i.item_revenue, 0.00)
        AS item_revenue,

    COALESCE(i.freight_value, 0.00)
        AS freight_value,

    COALESCE(i.item_total_value, 0.00)
        AS item_total_value,

    COALESCE(p.total_payment_value, 0.00)
        AS total_payment_value,

    p.primary_payment_type,
    p.maximum_installments,
    p.payment_record_count,
    p.payment_method_count,

    r.review_score,
    r.review_creation_date,
    r.review_answer_timestamp,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN
            o.order_delivered_customer_date::DATE
            - o.order_purchase_timestamp::DATE
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN
            o.order_delivered_customer_date::DATE
            - o.order_estimated_delivery_date::DATE
        ELSE NULL
    END AS delivery_variance_days,

    -- Compare calendar dates rather than full timestamps.
    -- Delivery on the promised date counts as on time.
    CASE
        WHEN o.order_status <> 'delivered'
          OR o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN NULL

        WHEN o.order_delivered_customer_date::DATE
             > o.order_estimated_delivery_date::DATE
        THEN TRUE

        ELSE FALSE
    END AS is_late_delivery,

    CASE
        WHEN o.order_status = 'delivered' THEN TRUE
        ELSE FALSE
    END AS is_delivered,

    CASE
        WHEN i.order_id IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_item_record,

    CASE
        WHEN p.order_id IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_payment_record,

    CASE
        WHEN r.order_id IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_review_record

FROM raw.orders AS o

LEFT JOIN order_item_summary AS i
    ON o.order_id = i.order_id

LEFT JOIN analytics.fact_order_payments AS p
    ON o.order_id = p.order_id

LEFT JOIN analytics.fact_order_reviews AS r
    ON o.order_id = r.order_id;