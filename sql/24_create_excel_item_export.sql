-- Creates a flattened item-level dataset for Excel and Power BI.
-- Grain: one row represents one item within one order.

CREATE OR REPLACE VIEW analytics.excel_order_items_export AS

SELECT
    oi.order_id,
    oi.order_item_id,

    -- Order information
    oi.order_purchase_timestamp,
    oi.order_purchase_date,
    oi.order_purchase_month,
    EXTRACT(YEAR FROM oi.order_purchase_date)::INTEGER AS order_year,
    EXTRACT(MONTH FROM oi.order_purchase_date)::INTEGER AS order_month_number,
    TO_CHAR(oi.order_purchase_date, 'FMMonth') AS order_month_name,
    oi.order_status,
    oi.is_delivered,

    -- Customer information
    oi.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COALESCE(cs.completed_orders, 0) AS customer_completed_orders,
    COALESCE(cs.customer_segment, 'No completed order') AS customer_segment,
    CASE
        WHEN COALESCE(cs.completed_orders, 0) > 1 THEN TRUE
        ELSE FALSE
    END AS is_repeat_customer,

    -- Product information
    oi.product_id,
    COALESCE(
        p.product_category_name_english,
        'unknown'
    ) AS product_category,
    p.product_category_name_portuguese,

    -- Seller information
    oi.seller_id,
    s.seller_city,
    s.seller_state,

    -- Financial information
    oi.item_revenue,
    oi.freight_value,
    oi.item_total_value,

    -- Shipping information
    oi.shipping_limit_date,
    oi.order_delivered_carrier_date,
    oi.shipped_after_limit

FROM analytics.fact_order_items AS oi

LEFT JOIN analytics.dim_customers AS c
    ON oi.customer_id = c.customer_id

LEFT JOIN analytics.customer_summary AS cs
    ON c.customer_unique_id = cs.customer_unique_id

LEFT JOIN analytics.dim_products AS p
    ON oi.product_id = p.product_id

LEFT JOIN analytics.dim_sellers AS s
    ON oi.seller_id = s.seller_id;