-- ============================================================
-- DATE DIMENSION
--
-- Purpose:
-- 1. Create one row for every calendar date in the dataset.
-- 2. Support Power BI time intelligence and drill-downs.
-- 3. Provide consistent year, quarter, month and weekday fields.
-- ============================================================

CREATE OR REPLACE VIEW analytics.dim_date AS

WITH date_bounds AS (
    SELECT
        MIN(order_purchase_date) AS minimum_date,
        MAX(order_purchase_date) AS maximum_date
    FROM analytics.fact_orders
),

calendar AS (
    SELECT
        GENERATE_SERIES(
            minimum_date,
            maximum_date,
            INTERVAL '1 day'
        )::DATE AS calendar_date

    FROM date_bounds
)

SELECT
    calendar_date,

    TO_CHAR(
        calendar_date,
        'YYYYMMDD'
    )::INTEGER AS date_key,

    EXTRACT(
        YEAR FROM calendar_date
    )::INTEGER AS calendar_year,

    EXTRACT(
        QUARTER FROM calendar_date
    )::INTEGER AS calendar_quarter_number,

    'Q' || EXTRACT(
        QUARTER FROM calendar_date
    )::INTEGER AS calendar_quarter,

    EXTRACT(
        MONTH FROM calendar_date
    )::INTEGER AS month_number,

    TO_CHAR(
        calendar_date,
        'FMMonth'
    ) AS month_name,

    TO_CHAR(
        calendar_date,
        'YYYY-MM'
    ) AS year_month,

    DATE_TRUNC(
        'month',
        calendar_date
    )::DATE AS month_start_date,

    EXTRACT(
        ISODOW FROM calendar_date
    )::INTEGER AS weekday_number,

    TO_CHAR(
        calendar_date,
        'FMDay'
    ) AS weekday_name,

    CASE
        WHEN EXTRACT(ISODOW FROM calendar_date) IN (6, 7)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend

FROM calendar;