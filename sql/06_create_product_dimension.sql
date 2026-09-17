-- ============================================================
-- CLEANED PRODUCT DIMENSION
--
-- Purpose:
-- 1. Preserve every product from the raw dataset.
-- 2. Convert blank categories to "unknown".
-- 3. add the two missing English translations.
-- 4. Correct the source dataset's "lenght" spelling using aliases.
-- 5. Calculate product volume for later analysis.
-- ============================================================

CREATE OR REPLACE VIEW analytics.dim_products AS

SELECT
    p.product_id,

    NULLIF(
        TRIM(p.product_category_name),
        ''
    ) AS product_category_name_portuguese,

    CASE
        WHEN NULLIF(TRIM(p.product_category_name), '') IS NULL
            THEN 'unknown'

        WHEN p.product_category_name = 'pc_gamer'
            THEN 'pc_gaming'

        WHEN p.product_category_name =
             'portateis_cozinha_e_preparadores_de_alimentos'
            THEN 'portable_kitchen_and_food_preparation'

        WHEN t.product_category_name_english IS NULL
            THEN p.product_category_name

        ELSE t.product_category_name_english
    END AS product_category_name_english,

    p.product_name_lenght AS product_name_length,
    p.product_description_lenght AS product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    CASE
        WHEN p.product_length_cm IS NOT NULL
         AND p.product_height_cm IS NOT NULL
         AND p.product_width_cm IS NOT NULL
        THEN
            p.product_length_cm
            * p.product_height_cm
            * p.product_width_cm
        ELSE NULL
    END AS product_volume_cm3

FROM raw.products AS p

LEFT JOIN raw.product_category_translation AS t
    ON p.product_category_name = t.product_category_name;