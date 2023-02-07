----------------------------------
-- Author: Dwiky Kurnia Lazuardi
-- Date: 12/2022 
----------------------------------
/* --------------------
   Case Study Questions
   --------------------

B) Data Analysis Questions
1. How many customers has Foodie-Fi ever had?
2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
6. What is the number and percentage of customer plans after their initial free trial?
7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
8. How many customers have upgraded to an annual plan in 2020?
9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
*/

/* --------------------
   Case Study Solutions
   --------------------*/
   
-- B) Data Analysis Questions  
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT EXTRACT(MONTH FROM start_date) AS month, COUNT(EXTRACT(MONTH FROM start_date)) AS count
FROM subscriptions
WHERE plan_id = 0
GROUP BY month;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT s.plan_id, plan_name, COUNT(*) AS events_2021
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM start_date) > '2020'
GROUP BY plan_name
ORDER BY plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT customer_id) AS customer_count, ROUND((COUNT(DISTINCT customer_id)/1000 * 100),1) AS percentage
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE plan_name = 'churn';

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT COUNT(customer_id) AS churn_count, 
	   ROUND(COUNT(customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100, 0) AS churn_percentage
FROM (
SELECT customer_id, plan_id, start_date, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS row_num
FROM subscriptions
ORDER BY customer_id, start_date) AS a
WHERE plan_id = 4 AND row_num = 2;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH next_plan AS (
SELECT customer_id, start_date, plan_id, LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
FROM subscriptions
ORDER BY customer_id, start_date )

SELECT next_plan, COUNT(*) AS conversion, ROUND(COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) * 100, 1) AS conversion_percentage
FROM next_plan
WHERE plan_id = 0
GROUP BY next_plan;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH next_plan AS (
SELECT customer_id, plan_id, start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM subscriptions
WHERE start_date <= '2020-12-31'
), 

customer_breakdown AS (
  SELECT 
    plan_id, 
    COUNT(DISTINCT customer_id) AS customers
  FROM next_plan
  WHERE 
    (next_date IS NOT NULL AND (start_date < '2020-12-31' 
      AND next_date > '2020-12-31'))
    OR (next_date IS NULL AND start_date < '2020-12-31')
  GROUP BY plan_id)

SELECT plan_id, customers, 
  ROUND(100 * CAST(customers AS NUMERIC) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id (SALAH)

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions
WHERE plan_id = 3 AND EXTRACT(YEAR FROM start_date) = '2020';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trial_plan AS (
SELECT *
FROM subscriptions
WHERE plan_id = 0
),

annual_pro AS (
SELECT *
FROM subscriptions
WHERE plan_id = 3
)

SELECT ROUND(AVG(DATEDIFF(a.start_date, t.start_date)), 0) AS average_date_difference
FROM trial_plan AS t
LEFT JOIN annual_pro AS a
ON t.customer_id = a.customer_id;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial_plan AS (
SELECT *
FROM subscriptions
WHERE plan_id = 0
),

annual_pro AS (
SELECT *
FROM subscriptions
WHERE plan_id = 3
),

date_dif AS (
SELECT DATEDIFF(a.start_date, t.start_date) AS date_difference
FROM trial_plan AS t
LEFT JOIN annual_pro AS a
ON t.customer_id = a.customer_id
)

SELECT breakdown, COUNT(*) AS customers
FROM (SELECT CASE WHEN date_difference >= 0 AND date_difference <= 30 THEN 'a) 0 - 30 days'
       			  WHEN date_difference >= 31 AND date_difference <= 60 THEN 'b) 31 - 60 days'
                  WHEN date_difference >= 61 AND date_difference <= 90 THEN 'c) 61 - 90 days'
                  WHEN date_difference >= 91 AND date_difference <= 120 THEN 'd) 91 - 120 days'
                  WHEN date_difference >= 121 AND date_difference <= 150 THEN 'e) 121 - 150 days'
                  WHEN date_difference >= 151 AND date_difference <= 180 THEN 'f) 151 - 180 days'
                  WHEN date_difference >= 181 AND date_difference <= 210 THEN 'g) 181 - 210 days'
                  WHEN date_difference >= 211 AND date_difference <= 240 THEN 'h) 211 - 240 days'
                  WHEN date_difference >= 241 AND date_difference <= 270 THEN 'i) 241 - 270 days'
                  WHEN date_difference >= 271 AND date_difference <= 300 THEN 'j) 271 - 300 days'
                  WHEN date_difference >= 301 AND date_difference <= 330 THEN 'k) 301 - 330 days'
                  WHEN date_difference >= 331 AND date_difference <= 360 THEN 'l) 331 - 360 days'
                  END AS breakdown
				  FROM date_dif
     			  WHERE date_difference IS NOT NULL) AS a
GROUP BY breakdown
ORDER BY breakdown;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH next_plan AS (
SELECT customer_id, start_date, plan_id, LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
FROM subscriptions
WHERE EXTRACT(YEAR FROM start_date) = '2020'
ORDER BY customer_id, start_date )

SELECT COUNT(*) AS downgraded
FROM next_plan
WHERE plan_id = 2 AND plan_id = 1;