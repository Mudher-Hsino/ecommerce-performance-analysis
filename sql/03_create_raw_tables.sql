-- Raw tables mirror the original CSV files.
-- Constraints will be added later after completing data-quality checks.

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id VARCHAR(32),
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);-- Seller location data

CREATE TABLE IF NOT EXISTS raw.sellers (
    seller_id VARCHAR(32),
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);-- Product-category translations

CREATE TABLE IF NOT EXISTS raw.product_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);


-- Products
-- The source CSV misspells "length" as "lenght".
-- We preserve the original raw column names and correct them later.

CREATE TABLE IF NOT EXISTS raw.products (
    product_id VARCHAR(32),
    product_category_name VARCHAR(100),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);


-- Orders

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id VARCHAR(32),
    customer_id VARCHAR(32),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);


-- Individual products within each order

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id VARCHAR(32),
    order_item_id INTEGER,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12, 2),
    freight_value NUMERIC(12, 2)
);


-- Order payments

CREATE TABLE IF NOT EXISTS raw.order_payments (
    order_id VARCHAR(32),
    payment_sequential INTEGER,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12, 2)
);


-- Customer reviews

CREATE TABLE IF NOT EXISTS raw.order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- Brazilian postcode coordinates

CREATE TABLE IF NOT EXISTS raw.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);