----------------------------------
-- Author: Dwiky Kurnia Lazuardi
-- Date: 12/2022 
----------------------------------
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

/* --------------------
   Case Study Solutions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_spent
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT customer_id, order_date, product_name
FROM sales AS s
INNER JOIN menu AS m
ON s.product_id = m.product_id
WHERE order_date = '2021-01-01';

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, s.product_id, COUNT(s.product_id) AS amount_purchased
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.product_id
ORDER BY amount_purchased DESC;

-- 5. Which item was the most popular for each customer?
WITH rank_cte AS (
SELECT product_name, s.customer_id, s.product_id, COUNT(*) as buy_count, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY buy_count DESC) AS rank
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id, product_id
ORDER BY customer_id, rank
)

SELECT customer_id, product_name
FROM rank_cte
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH afterjoin_cte AS (
SELECT s.customer_id, join_date, order_date, product_name, s.product_id,
	   DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS rank
FROM sales AS s
INNER JOIN members AS m
ON s.customer_id = m.customer_id
INNER JOIN menu AS me
ON s.product_id = me.product_id
WHERE order_date >= join_date
)

SELECT customer_id, order_date, product_name
FROM afterjoin_cte
WHERE rank = 1;
  
-- 7. Which item was purchased just before the customer became a member?
WITH beforejoin_cte AS (
SELECT s.customer_id, join_date, order_date, product_name, s.product_id,
	   DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS rank
FROM sales AS s
INNER JOIN members AS m
ON s.customer_id = m.customer_id
INNER JOIN menu AS me
ON s.product_id = me.product_id
WHERE order_date < join_date
)

SELECT customer_id, order_date, product_name
FROM beforejoin_cte
WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH beforejoin_cte AS (
SELECT s.customer_id, join_date, order_date, product_name, s.product_id, price
FROM sales AS s
INNER JOIN members AS m
ON s.customer_id = m.customer_id
INNER JOIN menu AS me
ON s.product_id = me.product_id
WHERE order_date < join_date
)

SELECT customer_id, COUNT(*) AS total_items, SUM(price) AS amount_spent
FROM beforejoin_cte
GROUP BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS total_points
FROM (
SELECT s.customer_id, 
  	CASE WHEN product_name = 'curry' THEN price * 10
    	 WHEN product_name = 'ramen' THEN price * 10
         WHEN product_name = 'sushi' THEN price * 20
    END AS points
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id ) AS a
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH total_points AS (
SELECT s.customer_id, order_date, join_date, DATE_ADD(join_date, INTERVAL 6 DAY) AS first_week, s.product_id,
	CASE WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY) THEN price * 20
   		 WHEN order_date < join_date AND s.product_id = 1 THEN price * 20
         WHEN order_date < join_date AND s.product_id = 2 THEN price * 10
  		 WHEN order_date < join_date AND s.product_id = 3 THEN price * 10
  		 WHEN order_date > DATE_ADD(join_date, INTERVAL 6 DAY) AND order_date < '2021-01-31' AND s.product_id = 1 THEN price * 20
   		 WHEN order_date > DATE_ADD(join_date, INTERVAL 6 DAY) AND order_date < '2021-01-31' AND s.product_id = 2 THEN price * 10
   		 WHEN order_date > DATE_ADD(join_date, INTERVAL 6 DAY) AND order_date < '2021-01-31' AND s.product_id = 3 THEN price * 10
    END AS total_points
FROM sales AS s
INNER JOIN members AS ms
ON s.customer_id = ms.customer_id
INNER JOIN menu as m
ON s.product_id = m.product_id
)

SELECT customer_id, SUM(total_points) AS points
FROM total_points
GROUP BY customer_id;