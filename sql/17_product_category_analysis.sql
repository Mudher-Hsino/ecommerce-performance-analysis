-- ============================================================
-- PRODUCT-CATEGORY PERFORMANCE
--
-- Scope:
-- Items from delivered orders only.
--
-- Financial definition:
-- Product sales use item price and exclude freight.
-- ============================================================

WITH category_performance AS (
    SELECT
        p.product_category_name_english
            AS product_category,

        SUM(
            oi.item_revenue
        ) AS product_sales,

        COUNT(*) AS items_sold,

        COUNT(
            DISTINCT oi.order_id
        ) AS order_count,

        ROUND(
            AVG(oi.item_revenue),
            2
        ) AS average_item_price

    FROM analytics.fact_order_items AS oi

    INNER JOIN analytics.dim_products AS p
        ON oi.product_id = p.product_id

    WHERE oi.is_delivered = TRUE

    GROUP BY p.product_category_name_english
)

SELECT
    product_category,

    ROUND(
        product_sales,
        2
    ) AS product_sales,

    items_sold,
    order_count,
    average_item_price,

    ROUND(
        100.0
        * product_sales
        / NULLIF(
            SUM(product_sales) OVER (),
            0
        ),
        2
    ) AS sales_share_pct,

    RANK() OVER (
        ORDER BY product_sales DESC
    ) AS sales_rank

FROM category_performance

ORDER BY sales_rank, product_category;

-- ============================================================
-- ANALYSIS 2: Category year-over-year performance
--
-- Comparison:
-- March-August 2018 versus March-August 2017.
--
-- HAVING requirement:
-- Include only established categories with at least 50 orders
-- during the 2017 comparison period.
-- ============================================================

WITH category_periods AS (
    SELECT
        p.product_category_name_english
            AS product_category,

        SUM(
            CASE
                WHEN oi.order_purchase_month
                     BETWEEN DATE '2017-03-01'
                         AND DATE '2017-08-01'
                THEN oi.item_revenue
                ELSE 0
            END
        ) AS sales_mar_aug_2017,

        SUM(
            CASE
                WHEN oi.order_purchase_month
                     BETWEEN DATE '2018-03-01'
                         AND DATE '2018-08-01'
                THEN oi.item_revenue
                ELSE 0
            END
        ) AS sales_mar_aug_2018,

        COUNT(
            DISTINCT CASE
                WHEN oi.order_purchase_month
                     BETWEEN DATE '2017-03-01'
                         AND DATE '2017-08-01'
                THEN oi.order_id
                ELSE NULL
            END
        ) AS orders_mar_aug_2017,

        COUNT(
            DISTINCT CASE
                WHEN oi.order_purchase_month
                     BETWEEN DATE '2018-03-01'
                         AND DATE '2018-08-01'
                THEN oi.order_id
                ELSE NULL
            END
        ) AS orders_mar_aug_2018

    FROM analytics.fact_order_items AS oi

    INNER JOIN analytics.dim_products AS p
        ON oi.product_id = p.product_id

    WHERE oi.is_delivered = TRUE

    GROUP BY p.product_category_name_english

    HAVING COUNT(
        DISTINCT CASE
            WHEN oi.order_purchase_month
                 BETWEEN DATE '2017-03-01'
                     AND DATE '2017-08-01'
            THEN oi.order_id
            ELSE NULL
        END
    ) >= 50
)

SELECT
    product_category,

    ROUND(
        sales_mar_aug_2017,
        2
    ) AS sales_mar_aug_2017,

    ROUND(
        sales_mar_aug_2018,
        2
    ) AS sales_mar_aug_2018,

    ROUND(
        sales_mar_aug_2018 - sales_mar_aug_2017,
        2
    ) AS sales_change,

    ROUND(
        100.0
        * (sales_mar_aug_2018 - sales_mar_aug_2017)
        / NULLIF(sales_mar_aug_2017, 0),
        2
    ) AS sales_growth_pct,

    orders_mar_aug_2017,
    orders_mar_aug_2018,

    ROUND(
        100.0
        * (orders_mar_aug_2018 - orders_mar_aug_2017)
        / NULLIF(orders_mar_aug_2017, 0),
        2
    ) AS order_growth_pct

FROM category_periods

ORDER BY sales_growth_pct ASC, product_category;