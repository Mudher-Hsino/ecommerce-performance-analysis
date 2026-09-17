# Data Quality Summary

## Objective

The raw Olist tables were assessed for completeness, uniqueness,
validity and referential integrity before business KPIs were calculated.

Raw source data remains unchanged in the `raw` schema. Cleaning and
deduplication rules are implemented through views in the `analytics`
schema.

## Import validation

All nine source tables matched their expected row counts.

| Table | Rows |
|---|---:|
| customers | 99,441 |
| geolocation | 1,000,163 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 99,224 |
| orders | 99,441 |
| product_category_translation | 71 |
| products | 32,951 |
| sellers | 3,095 |

## Key and relationship checks

- `orders.order_id` is complete and unique.
- `order_items` is unique by `order_id + order_item_id`.
- `order_payments` is unique by `order_id + payment_sequential`.
- Customer, product, seller and translation identifiers are complete
  and unique.
- No orphan records were found across the core table relationships.

## Reviews

The raw reviews table contains:

- 99,224 rows
- 98,410 distinct review IDs
- 98,673 distinct reviewed orders
- 814 extra rows beyond unique review IDs
- 551 extra rows beyond unique order IDs

Joining the raw review table directly to orders could duplicate order
records and distort metrics.

### Treatment

`analytics.fact_order_reviews` uses `ROW_NUMBER()` to retain the latest
review per order. The resulting view contains 98,673 unique order IDs.

## Order dates

Missing timestamp values were identified:

| Column | Missing | Percentage |
|---|---:|---:|
| order_approved_at | 160 | 0.16% |
| order_delivered_carrier_date | 1,783 | 1.79% |
| order_delivered_customer_date | 2,965 | 2.98% |

These values mainly reflect cancelled, unavailable or incomplete orders
and are therefore structural missing values rather than import errors.

### Treatment

The missing dates remain `NULL`. They are not replaced with invented
dates because that would corrupt delivery-time calculations.

## Product categories

- 610 products have blank category strings.
- These represent 1.85% of products.
- Two categories are missing from the English translation table:
  - `pc_gamer`: 3 products
  - `portateis_cozinha_e_preparadores_de_alimentos`: 10 products
- Two products have incomplete physical measurements.

### Treatment

- Blank strings are normalised using `NULLIF(TRIM(column), '')`.
- Blank categories are labelled `unknown`.
- The two missing translations are mapped manually.
- Missing physical measurements remain `NULL`.

## Payments and freight

- No negative item prices were found.
- No negative freight values were found.
- No negative payment values were found.
- 383 item rows have zero freight, likely representing free shipping.
- Nine payment rows have zero value:
  - six voucher records
  - three `not_defined` records
- Two payment records have non-positive instalment values.
- All review scores fall within the valid range of 1–5.

### Treatment

Zero-freight rows are retained. Zero-value payment and instalment
anomalies are preserved and documented because they have negligible
financial impact and removing them would unnecessarily alter the raw
source.

## Geolocation

The raw geolocation table contains many records per postcode prefix.
Joining it directly to sales data would create severe row duplication.

### Treatment

`analytics.dim_geolocation` aggregates the 1,000,163 raw rows into
19,015 unique postcode prefixes using:

- average latitude and longitude
- most common city and state
- source-row count for auditing

## Conclusion

The analytical layer is suitable for business analysis after applying
the documented grain, deduplication and missing-value rules. The main
remaining limitations come from unavailable business data, including
inventory, profit margin, refunds, marketing activity and carrier
identity.