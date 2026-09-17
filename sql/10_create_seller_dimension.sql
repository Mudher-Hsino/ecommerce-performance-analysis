-- ============================================================
-- CLEANED SELLER DIMENSION
--
-- Purpose:
-- 1. Keep one record per seller.
-- 2. Store postcode prefixes as five-character text.
-- 3. Standardise city and state formatting.
-- ============================================================

CREATE OR REPLACE VIEW analytics.dim_sellers AS

SELECT
    seller_id,

    LPAD(
        seller_zip_code_prefix::TEXT,
        5,
        '0'
    ) AS seller_zip_code_prefix,

    INITCAP(
        TRIM(seller_city)
    ) AS seller_city,

    UPPER(
        TRIM(seller_state)
    ) AS seller_state

FROM raw.sellers;