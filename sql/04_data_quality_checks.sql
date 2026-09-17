-- Check the number and uniqueness of customer identifiers.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customer_ids
FROM raw.customers;

-- ============================================================
-- CHECK 1: Verify imported row counts
-- Purpose: Confirm that every raw CSV loaded completely.
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM raw.geolocation

UNION ALL

SELECT 'order_items', COUNT(*)
FROM raw.order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM raw.order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM raw.order_reviews

UNION ALL

SELECT 'orders', COUNT(*)
FROM raw.orders

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM raw.product_category_translation

UNION ALL

SELECT 'products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM raw.sellers

ORDER BY table_name;

-- ============================================================
-- CHECK 2: Validate the orders table identifier
-- Expected grain: one row per order_id
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT(order_id) - COUNT(DISTINCT order_id) AS duplicate_order_id_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids
FROM raw.orders;

-- ============================================================
-- CHECK 3: Validate the order_items composite identifier
-- Expected grain: one row per order_id + order_item_id
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS distinct_order_item_keys,
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_order_item_rows,
    SUM(
        CASE
            WHEN order_id IS NULL OR order_item_id IS NULL THEN 1
            ELSE 0
        END
    ) AS null_key_rows
FROM raw.order_items;

-- ============================================================
-- CHECK 4: Validate the order_payments composite identifier
-- Expected grain: one row per order_id + payment_sequential
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential))
        AS distinct_payment_keys,
    COUNT(*) - COUNT(DISTINCT (order_id, payment_sequential))
        AS duplicate_payment_rows,
    SUM(
        CASE
            WHEN order_id IS NULL
              OR payment_sequential IS NULL
            THEN 1
            ELSE 0
        END
    ) AS null_key_rows
FROM raw.order_payments;

-- ============================================================
-- CHECK 5: Profile the order_reviews table grain
-- Reviews are not guaranteed to be unique by review_id/order_id.
-- ============================================================

SELECT
    COUNT(*) AS total_review_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT order_id) AS distinct_reviewed_orders,
    COUNT(*) - COUNT(DISTINCT review_id)
        AS extra_rows_beyond_unique_review_ids,
    COUNT(*) - COUNT(DISTINCT order_id)
        AS extra_rows_beyond_unique_orders,
    SUM(
        CASE
            WHEN review_id IS NULL OR order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS null_key_rows
FROM raw.order_reviews;

-- ============================================================
-- CHECK 6: Validate dimension-table identifiers
-- Each identifier below should uniquely identify one row.
-- ============================================================

SELECT
    'customers.customer_id' AS checked_key,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_keys,
    COUNT(customer_id) - COUNT(DISTINCT customer_id)
        AS duplicate_key_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS null_key_rows
FROM raw.customers

UNION ALL

SELECT
    'products.product_id',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(product_id) - COUNT(DISTINCT product_id),
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END)
FROM raw.products

UNION ALL

SELECT
    'sellers.seller_id',
    COUNT(*),
    COUNT(DISTINCT seller_id),
    COUNT(seller_id) - COUNT(DISTINCT seller_id),
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END)
FROM raw.sellers

UNION ALL

SELECT
    'translation.category_name',
    COUNT(*),
    COUNT(DISTINCT product_category_name),
    COUNT(product_category_name)
        - COUNT(DISTINCT product_category_name),
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END)
FROM raw.product_category_translation

ORDER BY checked_key;

-- ============================================================
-- CHECK 7: Test relationships for unmatched foreign keys
-- An orphan row references an ID missing from its parent table.
-- ============================================================

SELECT
    'orders -> customers' AS relationship,
    COUNT(*) AS orphan_rows
FROM raw.orders AS o
LEFT JOIN raw.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'order_items -> orders',
    COUNT(*)
FROM raw.order_items AS oi
LEFT JOIN raw.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_items -> products',
    COUNT(*)
FROM raw.order_items AS oi
LEFT JOIN raw.products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'order_items -> sellers',
    COUNT(*)
FROM raw.order_items AS oi
LEFT JOIN raw.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT
    'order_payments -> orders',
    COUNT(*)
FROM raw.order_payments AS op
LEFT JOIN raw.orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_reviews -> orders',
    COUNT(*)
FROM raw.order_reviews AS r
LEFT JOIN raw.orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL

ORDER BY relationship;

-- ============================================================
-- CHECK 8: Measure missing values in important order dates
-- Some missing delivery dates may be valid for incomplete orders.
-- ============================================================

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END
    ) AS missing_purchase_dates,

    SUM(
        CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END
    ) AS missing_approval_dates,

    ROUND(
        100.0 * SUM(
            CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS missing_approval_pct,

    SUM(
        CASE
            WHEN order_delivered_carrier_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_carrier_dates,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_carrier_date IS NULL THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS missing_carrier_pct,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_customer_delivery_dates,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date IS NULL THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS missing_customer_delivery_pct,

    SUM(
        CASE
            WHEN order_estimated_delivery_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_estimated_dates

FROM raw.orders;

-- ============================================================
-- CHECK 9: Investigate missing order dates by order status
-- This distinguishes expected missingness from data-quality issues.
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,

    SUM(
        CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END
    ) AS missing_approval_dates,

    SUM(
        CASE
            WHEN order_delivered_carrier_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_carrier_dates,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_customer_delivery_dates

FROM raw.orders

GROUP BY order_status

ORDER BY order_count DESC;

SELECT
    COUNT(*) AS total_products,

    SUM(
        CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END
    ) AS null_category_names,

    SUM(
        CASE WHEN TRIM(product_category_name) = '' THEN 1 ELSE 0 END
    ) AS empty_category_names,

    SUM(
        CASE
            WHEN NULLIF(TRIM(product_category_name), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_category_names,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN NULLIF(TRIM(product_category_name), '') IS NULL
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS missing_category_pct,

    SUM(
        CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END
    ) AS missing_name_lengths,

    SUM(
        CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END
    ) AS missing_description_lengths,

    SUM(
        CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END
    ) AS missing_photo_counts,

    SUM(
        CASE
            WHEN product_weight_g IS NULL
              OR product_length_cm IS NULL
              OR product_height_cm IS NULL
              OR product_width_cm IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_physical_measurements

FROM raw.products;

-- ============================================================
-- CHECK 11: Find product categories without English translations
-- Blank source categories are excluded from this specific check.
-- ============================================================

SELECT
    p.product_category_name,
    COUNT(*) AS affected_products

FROM raw.products AS p

LEFT JOIN raw.product_category_translation AS t
    ON p.product_category_name = t.product_category_name

WHERE NULLIF(TRIM(p.product_category_name), '') IS NOT NULL
  AND t.product_category_name IS NULL

GROUP BY p.product_category_name

ORDER BY affected_products DESC;

-- ============================================================
-- CHECK 12: Validate monetary values, instalments and scores
-- Negative values are invalid; some zero values require review.
-- ============================================================

SELECT
    'negative item prices' AS quality_check,
    COUNT(*) AS affected_rows
FROM raw.order_items
WHERE price < 0

UNION ALL

SELECT
    'negative freight values',
    COUNT(*)
FROM raw.order_items
WHERE freight_value < 0

UNION ALL

SELECT
    'zero freight values',
    COUNT(*)
FROM raw.order_items
WHERE freight_value = 0

UNION ALL

SELECT
    'negative payment values',
    COUNT(*)
FROM raw.order_payments
WHERE payment_value < 0

UNION ALL

SELECT
    'zero payment values',
    COUNT(*)
FROM raw.order_payments
WHERE payment_value = 0

UNION ALL

SELECT
    'non-positive payment instalments',
    COUNT(*)
FROM raw.order_payments
WHERE payment_installments <= 0

UNION ALL

SELECT
    'invalid or missing review scores',
    COUNT(*)
FROM raw.order_reviews
WHERE review_score IS NULL
   OR review_score NOT BETWEEN 1 AND 5

ORDER BY quality_check;