----------------------------------
-- Author: Dwiky Kurnia Lazuardi
-- Date: 12/2022 
----------------------------------
/* --------------------
   Case Study Questions
   --------------------

A) Pizza Metrics
1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

B) Runner and Customer Experience
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?
*/

/* --------------------
   Case Study Solutions
   --------------------*/

-- Data Cleaning & Transformation
-- Data Cleaning For Table : customer_orders
DROP TEMPORARY TABLE temp_customer_orders
CREATE TEMPORARY TABLE temp_customer_orders
SELECT order_id, customer_id, pizza_id,
    CASE WHEN exclusions IS NULL OR exclusions LIKE 'null' THEN ''
    	 ELSE exclusions END AS exclusions,
    CASE WHEN extras IS NULL OR extras LIKE 'null' THEN ''
    	 ELSE extras END AS extras,
    order_time    		
FROM customer_orders

-- Data Cleaning For Table : runner_orders
DROP TEMPORARY TABLE temp_runner_orders
CREATE TEMPORARY TABLE temp_runner_orders
SELECT order_id, runner_id,
	CASE WHEN pickup_time IS NULL OR pickup_time LIKE 'null' THEN ''
    ELSE pickup_time END AS pickup_time,
    CASE WHEN distance IS NULL OR distance LIKE 'null' THEN ''
    	 WHEN distance LIKE '%km%' THEN TRIM('km' FROM distance)
    ELSE distance END AS distance,
    CASE WHEN duration IS NULL OR duration LIKE 'null' THEN ''
    	 WHEN duration LIKE '%minutes%' THEN TRIM('minutes' FROM duration)
         WHEN duration LIKE '%minute%' THEN TRIM('minute' FROM duration)
         WHEN duration LIKE '%mins%' THEN TRIM('mins' FROM duration)
    ELSE duration END AS duration,
    CASE WHEN cancellation IS NULL OR cancellation LIKE 'null' THEN ''
    ELSE cancellation END AS cancellation
FROM runner_orders

ALTER TABLE temp_runner_orders
MODIFY COLUMN pickup_time DATETIME,
MODIFY COLUMN distance FLOAT, 
MODIFY COLUMN duration INT;

-- A) Pizza Metrics   
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS order_count
FROM temp_customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS order_count
FROM temp_customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS order_count
FROM temp_runner_orders
WHERE pickup_time <> ''
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT co.pizza_id, pizza_name, COUNT(*) AS delivered_pizza_count
FROM temp_customer_orders AS co
LEFT JOIN temp_runner_orders AS ro
ON co.order_id = ro.order_id
LEFT JOIN pizza_names
ON co.pizza_id = pizza_names.pizza_id
WHERE cancellation = ''
GROUP BY co.pizza_id, pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(*) AS order_count
FROM temp_customer_orders AS co
LEFT JOIN pizza_names AS p
ON co.pizza_id = p.pizza_id
GROUP BY customer_id, pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(*) AS order_count
FROM temp_customer_orders
GROUP BY order_id
ORDER BY order_count DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
    SUM(CASE WHEN exclusions <> '' OR extras <> '' THEN 1
         ELSE 0 END) AS at_least_one_change,
    SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1
    	 ELSE 0 END) AS no_change
FROM temp_customer_orders
WHERE order_id NOT IN ('6', '9')
GROUP BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS delivered_count_w_exclusions_extras
FROM temp_customer_orders
WHERE order_id NOT IN ('6', '9')
AND exclusions <> '' AND extras <> '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS hour, COUNT(*) AS pizza_ordered_count
FROM temp_customer_orders
GROUP BY hour;

-- 10. What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS day, COUNT(*) AS pizza_ordered_count
FROM temp_customer_orders
GROUP BY day
ORDER BY pizza_ordered_count DESC;

-- B) Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT WEEK(registration_date) AS registration_week, COUNT(*) AS runners_count
FROM runners
GROUP BY registration_week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id, AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS avg_runner_pickup_time_in_minute
FROM temp_runner_orders AS ro
LEFT JOIN temp_customer_orders AS co
ON ro.order_id = co.order_id
WHERE ro.order_id NOT IN ('6', '9')
GROUP BY runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH prep_time_cte AS (
SELECT ro.order_id, runner_id, COUNT(co.order_id) AS pizza_count,TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS prep_time
FROM temp_runner_orders AS ro
LEFT JOIN temp_customer_orders AS co
ON ro.order_id = co.order_id
WHERE distance <> 0
GROUP BY ro.order_id
)

SELECT pizza_count, ROUND(AVG(prep_time), 2) AS avg_prep_time
FROM prep_time_cte
GROUP BY pizza_count;

-- 4. What was the average distance travelled for each customer?
SELECT customer_id, ROUND(AVG(distance), 2) AS avg_distance
FROM temp_runner_orders AS ro
LEFT JOIN temp_customer_orders AS co
ON ro.order_id = co.order_id
WHERE distance <> 0
GROUP BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) AS delivery_time_difference
FROM temp_runner_orders AS ro
LEFT JOIN temp_customer_orders AS co
ON ro.order_id = co.order_id
WHERE distance <> 0;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT ro.order_id, runner_id, COUNT(co.order_id) AS pizza_count, distance, duration, ROUND(distance / (duration / 60), 2) AS km_per_hour
FROM temp_runner_orders AS ro
LEFT JOIN temp_customer_orders AS co
ON ro.order_id = co.order_id
WHERE distance <> 0
GROUP BY ro.order_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id, ROUND(100 * SUM(CASE WHEN distance <> 0 THEN 1 ELSE 0 END) / COUNT(*), 0) AS percentage
FROM temp_runner_orders
GROUP BY runner_id;