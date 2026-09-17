-- ============================================================
-- MONTHLY SALES-PERFORMANCE ANALYSIS
--
-- Scope:
-- Delivered orders only.
--
-- Purpose:
-- 1. Track GMV, orders, customers and AOV by month.
-- 2. Include months with zero delivered orders.
-- 3. Calculate month-over-month GMV growth using LAG().
-- ============================================================

WITH monthly_sales AS (
    SELECT
        o.order_purchase_month AS month_start_date,

        ROUND(
            SUM(o.total_payment_value),
            2
        ) AS monthly_gmv,

        COUNT(
            DISTINCT o.order_id
        ) AS monthly_orders,

        COUNT(
            DISTINCT c.customer_unique_id
        ) AS monthly_customers

    FROM analytics.fact_orders AS o

    INNER JOIN analytics.dim_customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.is_delivered = TRUE

    GROUP BY o.order_purchase_month
),

month_bounds AS (
    SELECT
        MIN(order_purchase_month) AS first_month,
        MAX(order_purchase_month) AS last_month

    FROM analytics.fact_orders

    WHERE is_delivered = TRUE
),

calendar_months AS (
    SELECT DISTINCT
        d.month_start_date

    FROM analytics.dim_date AS d

    CROSS JOIN month_bounds AS b

    WHERE d.month_start_date
          BETWEEN b.first_month AND b.last_month
),

complete_months AS (
    SELECT
        cm.month_start_date,

        COALESCE(
            ms.monthly_gmv,
            0.00
        ) AS monthly_gmv,

        COALESCE(
            ms.monthly_orders,
            0
        ) AS monthly_orders,

        COALESCE(
            ms.monthly_customers,
            0
        ) AS monthly_customers,

        CASE
            WHEN COALESCE(ms.monthly_orders, 0) = 0
            THEN NULL

            ELSE ROUND(
                ms.monthly_gmv / ms.monthly_orders,
                2
            )
        END AS average_order_value

    FROM calendar_months AS cm

    LEFT JOIN monthly_sales AS ms
        ON cm.month_start_date = ms.month_start_date
),

months_with_previous AS (
    SELECT
        month_start_date,
        monthly_gmv,
        monthly_orders,
        monthly_customers,
        average_order_value,

        LAG(monthly_gmv) OVER (
            ORDER BY month_start_date
        ) AS previous_month_gmv

    FROM complete_months
)

SELECT
    month_start_date,
    monthly_gmv,
    monthly_orders,
    monthly_customers,
    average_order_value,
    previous_month_gmv,

    CASE
        WHEN previous_month_gmv IS NULL
          OR previous_month_gmv = 0
        THEN NULL

        ELSE ROUND(
            100.0
            * (monthly_gmv - previous_month_gmv)
            / previous_month_gmv,
            2
        )
    END AS month_over_month_growth_pct

FROM months_with_previous

ORDER BY month_start_date;

-- ============================================================
-- ANALYSIS 2: Rank established months by business performance
--
-- Scope:
-- January 2017 through August 2018.
-- Early incomplete/start-up months are excluded.
-- ============================================================

WITH monthly_performance AS (
    SELECT
        order_purchase_month AS month_start_date,

        ROUND(
            SUM(total_payment_value),
            2
        ) AS monthly_gmv,

        COUNT(
            DISTINCT order_id
        ) AS monthly_orders,

        ROUND(
            SUM(total_payment_value)
            / COUNT(DISTINCT order_id),
            2
        ) AS average_order_value

    FROM analytics.fact_orders

    WHERE is_delivered = TRUE

      AND order_purchase_month
          BETWEEN DATE '2017-01-01'
              AND DATE '2018-08-01'

    GROUP BY order_purchase_month
)

SELECT
    month_start_date,
    monthly_gmv,
    monthly_orders,
    average_order_value,

    RANK() OVER (
        ORDER BY monthly_gmv DESC
    ) AS gmv_rank,

    RANK() OVER (
        ORDER BY monthly_orders DESC
    ) AS order_volume_rank

FROM monthly_performance

ORDER BY gmv_rank, month_start_date;