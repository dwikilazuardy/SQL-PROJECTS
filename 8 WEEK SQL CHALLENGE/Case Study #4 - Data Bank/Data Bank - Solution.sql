----------------------------------
-- Author: Dwiky Kurnia Lazuardi
-- Date: 12/2022 
----------------------------------
/* --------------------
   Case Study Questions
   --------------------

A) Customer Nodes Exploration
1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

B) Customer Transactions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?
*/

/* --------------------
   Case Study Solutions
   --------------------*/
   
-- A) Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS total_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT region_id, COUNT(node_id) AS node_count
FROM customer_nodes
GROUP BY region_id;

-- 3. How many customers are allocated to each region?
SELECT region_id, COUNT(DISTINCT customer_id) AS customer_count
FROM customer_nodes
GROUP BY region_id;

-- 4. How many days on average are customers reallocated to a different node?
SELECT AVG(DATEDIFF(end_date, start_date)) AS average_date_difference
FROM customer_nodes
WHERE end_date <> '9999-12-31';

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- B) Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(*) AS total_type, SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH cte_deposit AS (
SELECT customer_id, COUNT(txn_type) AS deposit_count, SUM(txn_amount) AS deposit_amount
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)

SELECT AVG(deposit_count) AS avg_deposit_count,	AVG(deposit_amount) AS avg_deposit_amount
FROM cte_deposit;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH count_cte AS (
SELECT customer_id, EXTRACT(MONTH FROM txn_date) AS month, MONTHNAME(txn_date) AS month_name,
	SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
	SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
	SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
FROM data_bank.customer_transactions
GROUP BY month, customer_id
)

SELECT month, month_name, COUNT(*) AS customer_count
FROM count_cte
WHERE deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >=1)
GROUP BY month
ORDER BY month;

-- 4. What is the closing balance for each customer at the end of the month?
WITH total_amount_cte AS (
SELECT customer_id, EXTRACT(MONTH FROM txn_date) AS month, 
	   SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
           		ELSE -txn_amount END) AS total_amount
FROM customer_transactions
GROUP BY customer_id, month
)

SELECT customer_id, month, total_amount,
	   SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY month 
                               ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS closing_balance
FROM total_amount_cte;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?