-- ============================================================
-- CLEANED GEOLOCATION DIMENSION
--
-- Purpose:
-- 1. Reduce the raw table to one row per postcode prefix.
-- 2. Prevent row duplication in geographical joins.
-- 3. Use average coordinates as a representative location.
-- 4. Use the most common city and state for each postcode.
-- ============================================================

CREATE OR REPLACE VIEW analytics.dim_geolocation AS

SELECT
    LPAD(
        geolocation_zip_code_prefix::TEXT,
        5,
        '0'
    ) AS geolocation_zip_code_prefix,

    ROUND(
        AVG(geolocation_lat)::NUMERIC,
        6
    ) AS latitude,

    ROUND(
        AVG(geolocation_lng)::NUMERIC,
        6
    ) AS longitude,

    MODE() WITHIN GROUP (
        ORDER BY INITCAP(TRIM(geolocation_city))
    ) AS geolocation_city,

    MODE() WITHIN GROUP (
        ORDER BY UPPER(TRIM(geolocation_state))
    ) AS geolocation_state,

    COUNT(*) AS source_location_rows

FROM raw.geolocation

GROUP BY geolocation_zip_code_prefix;