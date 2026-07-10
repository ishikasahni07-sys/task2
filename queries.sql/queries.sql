-- =============================================================
-- queries.sql
-- Task 2: SQL for Data Extraction
-- Database: business.db (customers, products, orders)
-- =============================================================

-- =============================================================
-- SECTION 1 (Day 7-8): SQL FUNDAMENTALS
-- SELECT, WHERE, ORDER BY, LIMIT, GROUP BY, HAVING, JOINs
-- =============================================================

-- 1.1 Basic SELECT + WHERE
SELECT customer_name, region
FROM customers
WHERE region = 'North';

-- 1.2 ORDER BY + LIMIT: 10 most recent orders
SELECT order_id, customer_id, product_id, quantity, order_date
FROM orders
ORDER BY order_date DESC
LIMIT 10;

-- 1.3 GROUP BY: total quantity sold per product
SELECT product_id, SUM(quantity) AS total_qty
FROM orders
GROUP BY product_id
ORDER BY total_qty DESC;

-- 1.4 HAVING: products with more than 100 units sold
SELECT product_id, SUM(quantity) AS total_qty
FROM orders
GROUP BY product_id
HAVING SUM(quantity) > 100
ORDER BY total_qty DESC;

-- 1.5 INNER JOIN: orders with customer and product names
SELECT o.order_id, c.customer_name, p.product_name, o.quantity, o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
LIMIT 10;

-- 1.6 LEFT JOIN: all customers, even those with no orders
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS num_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY num_orders ASC;


-- =============================================================
-- SECTION 2 (Day 9-10): ADVANCED SQL
-- Subqueries, CTEs, Window Functions, Views
-- =============================================================

-- 2.1 Subquery: customers who spent above the average total spend
SELECT customer_id, customer_name FROM customers
WHERE customer_id IN (
    SELECT o.customer_id
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY o.customer_id
    HAVING SUM(o.quantity * p.price) > (
        SELECT AVG(cust_total) FROM (
            SELECT SUM(o2.quantity * p2.price) AS cust_total
            FROM orders o2
            JOIN products p2 ON o2.product_id = p2.product_id
            GROUP BY o2.customer_id
        )
    )
);

-- 2.2 CTE (WITH clause): revenue per product category
WITH order_value AS (
    SELECT o.order_id, p.category, (o.quantity * p.price) AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
)
SELECT category, ROUND(SUM(revenue), 2) AS total_revenue
FROM order_value
GROUP BY category
ORDER BY total_revenue DESC;

-- 2.3 Window function: ROW_NUMBER - most recent order per customer
SELECT * FROM (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders o
) WHERE rn = 1;

-- 2.4 Window function: RANK customers by total spend
WITH customer_spend AS (
    SELECT o.customer_id, SUM(o.quantity * p.price) AS total_spend
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY o.customer_id
)
SELECT customer_id, total_spend,
       RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM customer_spend;

-- 2.5 Window function: LAG/LEAD - month-over-month change in monthly revenue
WITH monthly_revenue AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(o.quantity * p.price) AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY month
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
       revenue - LAG(revenue) OVER (ORDER BY month) AS change_vs_prev_month,
       LEAD(revenue) OVER (ORDER BY month) AS next_month_revenue
FROM monthly_revenue
ORDER BY month;

-- 2.6 View: reusable view for order-level revenue
CREATE VIEW IF NOT EXISTS vw_order_revenue AS
SELECT o.order_id, o.customer_id, o.product_id, o.order_date,
       p.category, p.price, o.quantity,
       (o.quantity * p.price) AS revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id;

-- Example use of the view
SELECT * FROM vw_order_revenue LIMIT 10;


-- =============================================================
-- SECTION 3 (Day 11-13): 10 BUSINESS QUESTIONS
-- =============================================================

-- Q1. Top 5 products by sales (revenue)
SELECT p.product_name, ROUND(SUM(o.quantity * p.price), 2) AS total_sales
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 5;

-- Q2. Monthly sales trend
SELECT strftime('%Y-%m', o.order_date) AS month,
       ROUND(SUM(o.quantity * p.price), 2) AS monthly_sales
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY month
ORDER BY month;

-- Q3. Customer segmentation by spend (High / Medium / Low)
WITH customer_spend AS (
    SELECT o.customer_id, SUM(o.quantity * p.price) AS total_spend
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY o.customer_id
)
SELECT customer_id, total_spend,
       CASE
           WHEN total_spend >= 15000 THEN 'High'
           WHEN total_spend >= 7000  THEN 'Medium'
           ELSE 'Low'
       END AS segment
FROM customer_spend
ORDER BY total_spend DESC;

-- Q4. Revenue by region
SELECT c.region, ROUND(SUM(o.quantity * p.price), 2) AS revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.region
ORDER BY revenue DESC;

-- Q5. Average order value (AOV) per customer
SELECT o.customer_id, ROUND(AVG(o.quantity * p.price), 2) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY o.customer_id
ORDER BY avg_order_value DESC;

-- Q6. Repeat customers vs one-time customers
WITH order_counts AS (
    SELECT customer_id, COUNT(*) AS num_orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE WHEN num_orders > 1 THEN 'Repeat Customer' ELSE 'One-time Customer' END AS customer_type,
    COUNT(*) AS num_customers
FROM order_counts
GROUP BY customer_type;

-- Q7. Product category performance (revenue + units sold)
SELECT p.category,
       SUM(o.quantity) AS units_sold,
       ROUND(SUM(o.quantity * p.price), 2) AS revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Q8. Month-over-month sales growth %
WITH monthly_revenue AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(o.quantity * p.price) AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY month
)
SELECT month, revenue,
       ROUND(
         (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
         / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
       ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- Q9. Top 10 customers ranked by total spend
WITH customer_spend AS (
    SELECT o.customer_id, c.customer_name, SUM(o.quantity * p.price) AS total_spend
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON o.product_id = p.product_id
    GROUP BY o.customer_id, c.customer_name
)
SELECT customer_name, total_spend,
       RANK() OVER (ORDER BY total_spend DESC) AS rank
FROM customer_spend
ORDER BY rank
LIMIT 10;

-- Q10. Running total (cumulative) of monthly sales across the year
WITH monthly_revenue AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(o.quantity * p.price) AS revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY month
)
SELECT month, revenue,
       SUM(revenue) OVER (ORDER BY month) AS running_total
FROM monthly_revenue
ORDER BY month;
