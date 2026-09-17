# E-Commerce Performance Analysis

## Overview

I built this project to analyse the performance of a Brazilian e-commerce marketplace using SQL, Excel and Power BI.

The project covers the full process from loading and cleaning raw relational data to building an analytical database, calculating business KPIs and creating an interactive dashboard. I focused on sales performance, customers, product categories, geography, sellers, reviews and delivery performance.

## Dataset

The project uses the public Brazilian E-Commerce Dataset by Olist, which contains information about approximately 100,000 orders placed between 2016 and 2018.

The analysis combines nine related tables covering:

* Orders
* Customers
* Products
* Sellers
* Order items
* Payments
* Reviews
* Geolocation
* Product-category translations

The original dataset is available on [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

The large raw and processed CSV files are not included in this repository. They can be downloaded from the original source and recreated using the supplied SQL scripts.

## Tools used

* PostgreSQL
* SQL
* DBeaver
* Microsoft Excel
* Power BI

## Project workflow

### 1. Database setup and data preparation

I imported the nine source tables into PostgreSQL and used SQL to:

* Create separate raw and analytical schemas
* Check missing values and data quality
* Translate product-category names
* Create reusable fact and dimension tables
* Prepare order and order-item exports for Excel and Power BI

The SQL folder contains 24 numbered scripts showing the workflow in the order it was completed.

### 2. Business analysis

I used SQL to examine:

* Overall business KPIs
* Monthly order and revenue trends
* Product-category performance
* Customer behaviour and repeat purchases
* Revenue by state
* Delivery performance
* Review scores
* Seller performance

### 3. Excel analysis

I used Excel to explore the exported order and product data through:

* Data cleaning
* Formulas
* PivotTables
* Charts
* Monthly order analysis
* Product-category revenue analysis

### 4. Power BI dashboard

I created an interactive Power BI dashboard to bring the main findings together. It includes KPI cards, time trends, customer analysis, geographical performance, product categories and delivery performance.

## Main results

| KPI                  |          Result |
| -------------------- | --------------: |
| Completed orders     |          96,478 |
| Active customers     |          93,358 |
| Delivered-order GMV  | R$15.42 million |
| Average order value  |        R$159.85 |
| Average review score |            4.16 |
| Late-delivery rate   |           6.77% |

## Key findings

* Orders delivered on time received an average review score of **4.29**, compared with **2.27** for late deliveries
* São Paulo generated **37.41%** of delivered GMV, making it the marketplace's largest state by a considerable margin
* Rio de Janeiro contributed **13.33%** of GMV and Minas Gerais contributed **11.80%**
* Health and beauty was one of the strongest product categories by revenue
* Watches and gifts, bed and bath, sports and leisure, and computer accessories were also among the leading categories
* The customer segmentation identified **1,771 VIP repeat customers**
* Some high-revenue sellers also recorded relatively high late-shipment rates, showing that sales performance and delivery quality should be considered together

## Repository structure

```text
ecommerce-performance-analysis/
├── documentation/
│   ├── Data-quality notes
│   └── KPI definitions
├── excel/
│   └── ecommerce_sales_analysis.xlsx
├── powerbi/
│   └── ecommerce_performance_dashboard.pbix
├── sql/
│   ├── Database and schema setup
│   ├── Fact and dimension tables
│   ├── Data-quality checks
│   ├── Business KPI queries
│   └── Customer, product, delivery and seller analysis
├── .gitignore
└── README.md
```

## Opening the project

The Excel analysis can be opened using Microsoft Excel.

The interactive dashboard can be opened using Power BI Desktop:

```text
powerbi/ecommerce_performance_dashboard.pbix
```

The SQL scripts are numbered in the order they should be run. PostgreSQL is required to rebuild the database and analytical tables from the original Olist CSV files.

## What I learned

This project helped me understand how SQL, Excel and Power BI can be used together rather than as separate tools. SQL handled the relational data preparation and detailed analysis, Excel provided a quick way to investigate exported results, and Power BI allowed me to present the main findings in an accessible dashboard.

It also gave me experience checking data quality, defining KPIs carefully and turning technical outputs into findings that could support business decisions.
