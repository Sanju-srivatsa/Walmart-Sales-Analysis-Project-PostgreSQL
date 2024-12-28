-- Initialize the database
-- CREATE DATABASE walmartAnalysis;

-- Create the sales table
CREATE TABLE IF NOT EXISTS sales_data (
    invoice_id VARCHAR(30) PRIMARY KEY,
    branch_code VARCHAR(5) NOT NULL,
    city_name VARCHAR(30) NOT NULL,
    customer_category VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    unit_cost NUMERIC(10,2) NOT NULL, -- Exact numeric type for currency
    quantity_sold INT NOT NULL,
    tax_rate NUMERIC(6,4) NOT NULL, -- Exact numeric type for tax rates
    total_sales NUMERIC(12,4) NOT NULL, -- Exact numeric type for total sales
    transaction_date TIMESTAMP NOT NULL, -- Corrected DATETIME to TIMESTAMP
    transaction_time TIME NOT NULL,
    payment_method VARCHAR(15) NOT NULL,
    cost_of_goods NUMERIC(10,2) NOT NULL,
    gross_margin NUMERIC(11,9), -- Exact numeric type for high precision
    gross_profit NUMERIC(12,4),
    customer_rating NUMERIC(2,1) -- Exact numeric type for customer ratings
);

-- Preview the sales table
SELECT * FROM sales_data LIMIT 10;

-- Add a column to classify the time of day for transactions (if it doesn't already exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'sales_data' AND column_name = 'time_period'
    ) THEN
        ALTER TABLE sales_data ADD COLUMN time_period VARCHAR(20);
    END IF;
END $$;

-- Update the time_period column with values
UPDATE sales_data
SET time_period = CASE
    WHEN transaction_time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
    WHEN transaction_time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
    ELSE 'Evening'
END;

-- Add a column to store the day of the week (if it doesn't already exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'sales_data' AND column_name = 'day_of_week'
    ) THEN
        ALTER TABLE sales_data ADD COLUMN day_of_week VARCHAR(10);
    END IF;
END $$;

-- Update day_of_week column with the respective day names
UPDATE sales_data
SET day_of_week = TO_CHAR(transaction_date, 'Day');

-- Add a column to store the name of the month (if it doesn't already exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'sales_data' AND column_name = 'month_name'
    ) THEN
        ALTER TABLE sales_data ADD COLUMN month_name VARCHAR(10);
    END IF;
END $$;

-- Update the month_name column with month names
UPDATE sales_data
SET month_name = TO_CHAR(transaction_date, 'Month');

-- ---------------------- Basic Analysis ------------------------------

-- Count the number of unique cities
SELECT COUNT(DISTINCT city_name) AS unique_cities FROM sales_data;

-- List all branches and their respective cities
SELECT DISTINCT branch_code, city_name FROM sales_data;

-- ------------------ Product Performance Analysis --------------------

-- List all unique product categories
SELECT DISTINCT product_category FROM sales_data;

-- Identify the best-selling product categories by quantity
SELECT
    product_category,
    SUM(quantity_sold) AS total_quantity
FROM sales_data
GROUP BY product_category
ORDER BY total_quantity DESC;

-- Calculate monthly revenue
SELECT
    month_name,
    SUM(total_sales) AS monthly_revenue
FROM sales_data
GROUP BY month_name
ORDER BY monthly_revenue DESC;

-- Identify the product category generating the highest revenue
SELECT
    product_category,
    SUM(total_sales) AS category_revenue
FROM sales_data
GROUP BY product_category
ORDER BY category_revenue DESC;

-- ---------------------- Customer Insights ---------------------------

-- Analyze revenue contribution by customer type
SELECT
    customer_category,
    SUM(total_sales) AS revenue_by_category
FROM sales_data
GROUP BY customer_category
ORDER BY revenue_by_category DESC;

-- Gender distribution across branches
SELECT
    branch_code,
    gender,
    COUNT(*) AS gender_count
FROM sales_data
GROUP BY branch_code, gender
ORDER BY branch_code, gender_count DESC;

-- Identify popular product categories by gender
SELECT
    gender,
    product_category,
    COUNT(*) AS product_preference
FROM sales_data
GROUP BY gender, product_category
ORDER BY product_preference DESC;

-- ---------------------- Store Performance ---------------------------

-- Compare revenue across cities
SELECT
    city_name,
    SUM(total_sales) AS city_revenue
FROM sales_data
GROUP BY city_name
ORDER BY city_revenue DESC;

-- Compare branch performance based on revenue
SELECT
    branch_code,
    SUM(total_sales) AS branch_revenue
FROM sales_data
GROUP BY branch_code
ORDER BY branch_revenue DESC;

-- ---------------------- Customer Behavior ---------------------------

-- Identify the time period generating the most revenue
SELECT
    time_period,
    SUM(total_sales) AS revenue_by_period
FROM sales_data
GROUP BY time_period
ORDER BY revenue_by_period DESC;

-- Determine the average rating by time of day
SELECT
    time_period,
    ROUND(AVG(customer_rating)::NUMERIC, 2) AS avg_rating -- Cast AVG to NUMERIC before rounding
FROM sales_data
GROUP BY time_period
ORDER BY avg_rating DESC;

-- Determine the best day of the week based on average ratings
SELECT
    day_of_week,
    ROUND(AVG(customer_rating)::NUMERIC, 2) AS avg_rating -- Cast AVG to NUMERIC before rounding
FROM sales_data
GROUP BY day_of_week
ORDER BY avg_rating DESC;


-- ---------------------- Tax and Revenue Insights --------------------

-- Find the city with the highest average tax rate
SELECT
    city_name,
    ROUND(AVG(tax_rate)::NUMERIC, 2) AS avg_tax_rate
FROM sales_data
GROUP BY city_name
ORDER BY avg_tax_rate DESC;

-- Compare VAT contributions across customer types
SELECT
    customer_category,
    ROUND(AVG(tax_rate)::NUMERIC, 2) AS avg_tax_rate
FROM sales_data
GROUP BY customer_category
ORDER BY avg_tax_rate DESC;

-- --------------------------------------------------------------------
-- Analyze total sales trends by quarter
SELECT
    EXTRACT(QUARTER FROM transaction_date) AS quarter, 
    SUM(total_sales) AS total_revenue
FROM sales_data
GROUP BY quarter 
ORDER BY quarter; 

-- Categorize customer ratings into bins and count the number of transactions in each bin
SELECT
    CASE
        WHEN customer_rating BETWEEN 0 AND 2 THEN '0-2'
        WHEN customer_rating BETWEEN 2.1 AND 4 THEN '2-4'
        WHEN customer_rating BETWEEN 4.1 AND 6 THEN '4-6'
        WHEN customer_rating BETWEEN 6.1 AND 8 THEN '6-8'
        WHEN customer_rating BETWEEN 8.1 AND 10 THEN '8-10'
        ELSE 'Unknown'
    END AS rating_bin,
    COUNT(*) AS total_count
FROM sales_data
GROUP BY rating_bin
ORDER BY rating_bin;


