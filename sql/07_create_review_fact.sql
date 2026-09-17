-- ============================================================
-- CLEANED ORDER-REVIEW FACT VIEW
--
-- Purpose:
-- 1. Keep one latest review per order.
-- 2. Prevent duplicated rows when reviews join to orders.
-- 3. Convert blank review comments into SQL NULL values.
-- 4. Retain the original review count for auditing.
-- ============================================================

CREATE OR REPLACE VIEW analytics.fact_order_reviews AS

WITH ranked_reviews AS (
    SELECT
        review_id,
        order_id,
        review_score,

        NULLIF(
            TRIM(review_comment_title),
            ''
        ) AS review_comment_title,

        NULLIF(
            TRIM(review_comment_message),
            ''
        ) AS review_comment_message,

        review_creation_date,
        review_answer_timestamp,

        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS reviews_for_order,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC NULLS LAST,
                review_creation_date DESC NULLS LAST,
                review_id DESC
        ) AS review_rank

    FROM raw.order_reviews
)

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    reviews_for_order

FROM ranked_reviews

WHERE review_rank = 1;