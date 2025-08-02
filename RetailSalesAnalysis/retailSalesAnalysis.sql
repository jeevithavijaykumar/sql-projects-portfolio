-- ---------------------------------------------
 -- Retail Sales Analysis
 -- Goal: Clean, explore, and analyze retail sales data
-- ---------------------------------------------


--  Create Database
 CREATE DATABASE sql_portfolio_p1;
 

-- Drop table if it exists
DROP TABLE IF EXISTS retail_sales;

-- Create retail_sales table
CREATE TABLE retail_sales
 			( 
 			  transactions_id INT PRIMARY KEY,
 			  sale_date	DATE,
			  sale_time TIME,
			  customer_id INT,
			  gender VARCHAR (15),
			  age INT,
			  category VARCHAR(20),
			  quantiy	FLOAT,
			  price_per_unit	FLOAT,
			  cogs FLOAT,
			  total_sale FLOAT
			);


--  Preview data
SELECT * FROM retail_sales
LIMIT 10;

-- Count total records
SELECT COUNT(*) FROM
retail_sales;

----------------------------------------------
-- Data Cleaning
----------------------------------------------

SELECT * FROM retail_sales
WHERE 
	transactions_id IS NULL
	OR
	sale_date IS NULL
	OR
	sale_time IS NULL
	OR
	gender IS NULL
	OR
	category IS NULL
	OR
	quantiy IS NULL
	OR
	cogs IS NULL
	OR
	total_sale IS NULL;


--  Count how many rows have NULLs

SELECT COUNT(*) FROM retail_sales
WHERE 
  transactions_id IS NULL OR
  sale_date IS NULL OR
  sale_time IS NULL OR
  gender IS NULL OR
  category IS NULL OR
  quantity IS NULL OR
  cogs IS NULL OR
  total_sale IS NULL;
  
  
-- Remove NULL rows
DELETE FROM retail_sales
WHERE 
	transactions_id IS NULL
	OR
	sale_date IS NULL
	OR
	sale_time IS NULL
	OR
	gender IS NULL
	OR
	category IS NULL
	OR
	quantity IS NULL
	OR
	cogs IS NULL
	OR
	total_sale IS NULL;

-- ---------------------------------------------------
-- Data Exploration
-- ---------------------------------------------------


-- How many sales do we have?
SELECT COUNT(*) AS total_sales
FROM retail_sales;


-- How many unique customers?
SELECT COUNT(DISTINCT customer_id) AS total_sale
FROM retail_sales;

-- View unique product categories
SELECT DISTINCT(category) 
FROM retail_sales;


-- ---------------------------------------------------
--  Analysis & Business Insights
-- ---------------------------------------------------


-- Retrive all sales mades on a particular date
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';


 -- Transactions in 'Clothing' category with quantity > 4 fo a particular month
 SELECT *
 FROM retail_sales
 WHERE category= 'Clothing'
 	AND TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
	AND quantity >=4;


-- Total sales for each category

SELECT 
	category,
	SUM(total_sale) as new_sale
FROM retail_sales
GROUP BY category;

-- Average age of customers in 'Beauty' category

SELECT 
	ROUND(AVG(age),2) as Avg_age
FROM retail_sales
WHERE category = 'Beauty';


-- High-value transactions (total_sale > 1000)
SELECT *
FROM retail_sales
WHERE total_sale > 1000;


-- Number of transactions by gender and category
SELECT 
	category,
	gender,
	COUNT(*) as total_transactions
FROM retail_sales
GROUP BY 
	category,
	gender
ORDER BY category;


-- Average sale per month + best-selling month in each year
SELECT 
	year,
	month,
	avg_sale
FROM
(
SELECT
		EXTRACT(YEAR FROM sale_date) as year,
		EXTRACT(MONTH FROM sale_date) as month,
		AVG(total_sale) as avg_sale,
		RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) as rank
FROM retail_sales
GROUP BY year, month
) as t1
WHERE rank =1;


-- Top 5 customers by total sales
SELECT 
	 customer_id,
	 SUM(total_sale) as total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 5;


--  Number of unique customers per category
SELECT 
	COUNT(DISTINCT customer_id),
	category
FROM retail_sales
GROUP BY category;


-- Orders by time-of-day shift (Morning <12, Afternoon 12–17, Evening >17)
WITH hourly_sales AS
(
SELECT *,
	CASE 
		WHEN EXTRACT( HOUR FROM sale_time) <12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 and 17 THEN 'Afternoon'
		ELSE 'Evening'
	END AS shift
FROM retail_sales
)
SELECT 
	shift,
	COUNT(*) as total_orders
FROM hourly_sales
GROUP BY shift;


---------------------------------------------------
--End of SQL Project
---------------------------------------------------
 















