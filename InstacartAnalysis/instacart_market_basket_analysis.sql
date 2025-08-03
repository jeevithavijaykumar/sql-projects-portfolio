------------------------------------------------------
-- Instacart Market Basket Analysis 
------------------------------------------------------

-- Create database
CREATE DATABASE instacart_market_basket;


-- Drop existing tables if they exist
DROP TABLE IF EXISTS order_products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS aisles;
DROP TABLE IF EXISTS departments;


-- Create departments table
- Create departments table
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department VARCHAR(50)
);

-- Create aisles table
CREATE TABLE aisles (
    aisle_id INT PRIMARY KEY,
    aisle VARCHAR(50)
);

-- Create products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name TEXT,
    aisle_id INT REFERENCES aisles(aisle_id),
    department_id INT REFERENCES departments(department_id)
);

-- Create orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    eval_set VARCHAR(20),  
    order_number INT,
    order_dow INT,        
    order_hour_of_day INT,
    days_since_prior_order FLOAT
);

-- Create order_products table
CREATE TABLE order_products (
    order_id INT,
    product_id INT,
    add_to_cart_order INT,
    reordered INT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);



------------------------------------------------------
-- Data Cleaning
------------------------------------------------------

-- Orders table
SELECT COUNT(*) AS null_orders FROM orders
WHERE order_id IS NULL OR user_id IS NULL OR eval_set IS NULL 
  OR order_number IS NULL OR order_dow IS NULL 
  OR order_hour_of_day IS NULL;

-- Products table
SELECT COUNT(*) AS null_products FROM products
WHERE product_id IS NULL OR product_name IS NULL 
  OR aisle_id IS NULL OR department_id IS NULL;

-- Aisles table
SELECT COUNT(*) AS null_aisles FROM aisles
WHERE aisle_id IS NULL OR aisle IS NULL;

-- Departments table
SELECT COUNT(*) AS null_departments FROM departments
WHERE department_id IS NULL OR department IS NULL;

-- Order_Products table
SELECT COUNT(*) AS null_order_products FROM order_products
WHERE order_id IS NULL OR product_id IS NULL 
  OR add_to_cart_order IS NULL OR reordered IS NULL;


--  Delete rows with NULLs (if cleaning is needed)

-- Remove NULLs from orders
DELETE FROM orders
WHERE order_id IS NULL OR user_id IS NULL OR eval_set IS NULL 
  OR order_number IS NULL OR order_dow IS NULL 
  OR order_hour_of_day IS NULL;

-- Remove NULLs from products
DELETE FROM products
WHERE product_id IS NULL OR product_name IS NULL 
  OR aisle_id IS NULL OR department_id IS NULL;

-- Remove NULLs from aisles
DELETE FROM aisles
WHERE aisle_id IS NULL OR aisle IS NULL;

-- Remove NULLs from departments
DELETE FROM departments
WHERE department_id IS NULL OR department IS NULL;

-- Remove NULLs from order_products
DELETE FROM order_products
WHERE order_id IS NULL OR product_id IS NULL 
  OR add_to_cart_order IS NULL OR reordered IS NULL;


-- Duplicate orders
SELECT order_id, COUNT(*) 
FROM orders 
GROUP BY order_id 
HAVING COUNT(*) > 1;


-- Invalid order hour (should be 0–23)
SELECT * FROM orders
WHERE order_hour_of_day < 0 OR order_hour_of_day > 23;


-- Invalid reordered flag (should be 0 or 1)
SELECT * FROM order_products
WHERE reordered NOT IN (0, 1);



---------------------------------------------------------
--  Business Insights
---------------------------------------------------------

-- Total orders
SELECT COUNT(*) AS total_orders FROM orders;

-- Total unique users
SELECT COUNT(DISTINCT user_id) AS total_users FROM orders;

-- Total products
SELECT COUNT(*) AS total_products FROM products;


-- Orders by hour of day
SELECT order_hour_of_day, COUNT(*) AS order_count
FROM orders
GROUP BY order_hour_of_day
ORDER BY order_hour_of_day;


-- Orders by day of week (0 = Sunday)
SELECT order_dow, COUNT(*) AS order_count
FROM orders
GROUP BY order_dow
ORDER BY order_dow;


-- Average days between orders peruser
SELECT user_id, ROUND(AVG(days_since_prior_order)::numeric, 1) AS avg_days_between_orders
FROM orders
WHERE days_since_prior_order IS NOT NULL
GROUP BY user_id
ORDER BY avg_days_between_orders DESC
LIMIT 10;


-- Top 10 most frequently ordered products
SELECT p.product_name, COUNT(*) AS times_ordered
FROM order_products op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
ORDER BY times_ordered DESC
LIMIT 10;


-- Top 10 products by reorder rate (min 50 orders)
SELECT 
    p.product_name,
    ROUND(SUM(reordered) * 100.0 / COUNT(*), 2) AS reorder_rate
FROM order_products op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
HAVING COUNT(*) > 50  
ORDER BY reorder_rate DESC
LIMIT 10;


-- Top departments by number of orders
SELECT 
    d.department,
    COUNT(*) AS total_orders
FROM order_products op
JOIN products p ON op.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY total_orders DESC;


-- Average basket size per order
SELECT 
    ROUND(AVG(product_count), 1) AS avg_basket_size
FROM (
    SELECT order_id, COUNT(*) AS product_count
    FROM order_products
    GROUP BY order_id
) sub;


-- Most Loyal users (highest number of orders)
SELECT user_id, MAX(order_number) AS total_orders
FROM orders
GROUP BY user_id
ORDER BY total_orders DESC
LIMIT 10;


-- Aisles with most Unique Products
SELECT a.aisle, COUNT(DISTINCT p.product_id) AS unique_products
FROM products p
JOIN aisles a ON p.aisle_id = a.aisle_id
GROUP BY a.aisle
ORDER BY unique_products DESC
LIMIT 10;


-- Returning users vs one-time users
WITH user_orders AS (
    SELECT user_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY user_id
)
SELECT 
    COUNT(*) FILTER (WHERE order_count = 1) AS one_time_users,
    COUNT(*) FILTER (WHERE order_count > 1) AS returning_users
FROM user_orders;


-- Share of first-time vs. reordered products
SELECT 
    ROUND(SUM(CASE WHEN reordered = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS first_time_percent,
    ROUND(SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS reordered_percent
FROM order_products;


-- Average number of days between orders for each user
SELECT DISTINCT user_id,
       ROUND(AVG(days_since_prior_order) OVER (PARTITION BY user_id)::numeric, 1) AS avg_days_between_orders
FROM orders
WHERE days_since_prior_order IS NOT NULL
ORDER BY avg_days_between_orders DESC
LIMIT 10;



------------------------------------------------------
-- End of Instacart Market Basket Analysis Script
------------------------------------------------------
