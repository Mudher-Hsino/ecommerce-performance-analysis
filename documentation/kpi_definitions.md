# KPI Definitions

## Reporting scope

The headline executive KPIs use delivered orders only.

The dataset records transactions in Brazilian reais (BRL). Financial
figures represent marketplace transaction value, not Olist's net profit,
because commission, operating-cost and refund data are unavailable.

## Headline KPIs

| KPI | Business definition | SQL calculation | Validated value |
|---|---|---|---:|
| Delivered GMV | Total customer payment value associated with delivered orders, including freight | `SUM(total_payment_value)` where `is_delivered = TRUE` | R$15,422,461.77 |
| Completed Orders | Number of distinct delivered orders | `COUNT(DISTINCT order_id)` where `is_delivered = TRUE` | 96,478 |
| Active Customers | Distinct shoppers with at least one delivered order | `COUNT(DISTINCT customer_unique_id)` | 93,358 |
| Average Order Value | Average customer payment value per completed order | Delivered GMV / Completed Orders | R$159.85 |
| Average Review Score | Average latest review score for delivered orders with reviews | `AVG(review_score)` | 4.16 / 5 |
| Late Delivery Rate | Percentage of delivered orders arriving after the promised calendar date | Late delivered orders / delivered orders with valid delivery dates | 6.77% |

## Supporting financial definitions

### Product sales

Product sales are calculated using `order_items.price` and exclude
freight. This measure is used for product, category and seller analysis.

### Freight value

Freight value is analysed separately from product sales so that delivery
charges are not incorrectly attributed to product performance.

### Delivered GMV versus product sales

Delivered GMV uses the amount paid by the customer and includes freight.
Product sales use item prices only. These measures should not be treated
as interchangeable.

## Important analytical rules

- Use `customer_unique_id` for repeat-customer analysis.
- Use `customer_id` to join customers to individual orders.
- Use the latest review per order to prevent duplicated order rows.
- Compare delivery dates at calendar-date level rather than full
  timestamp level.
- Preserve all raw tables unchanged; cleaning occurs in the
  `analytics` schema.