
-- PIZZA RUNNER CASE STUDY SQL NOTEBOOK --

-- SCHEMA SETUP
CREATE SCHEMA IF NOT EXISTS pizza_runner;
USE pizza_runner;

-- DROP AND CREATE TABLES --

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners (runner_id, registration_date) VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);
INSERT INTO customer_orders (order_id, customer_id, pizza_id, exclusions, extras, order_time) VALUES
  (1, 101, 1, '', '', '2020-01-01 18:05:02'),
  (2, 101, 1, '', '', '2020-01-01 19:00:52'),
  (3, 102, 1, '', '', '2020-01-02 23:51:23'),
  (3, 102, 2, '', NULL, '2020-01-02 23:51:23'),
  (4, 103, 1, '4', '', '2020-01-04 13:23:46'),
  (4, 103, 1, '4', '', '2020-01-04 13:23:46'),
  (4, 103, 2, '4', '', '2020-01-04 13:23:46'),
  (5, 104, 1, 'null', '1', '2020-01-08 21:00:29'),
  (6, 101, 2, 'null', 'null', '2020-01-08 21:03:13'),
  (7, 105, 2, 'null', '1', '2020-01-08 21:20:29'),
  (8, 102, 1, 'null', 'null', '2020-01-09 23:54:33'),
  (9, 103, 1, '4', '1, 5', '2020-01-10 11:22:59'),
  (10, 104, 1, 'null', 'null', '2020-01-11 18:34:49'),
  (10, 104, 1, '2, 6', '1, 4', '2020-01-11 18:34:49');

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);
INSERT INTO runner_orders (order_id, runner_id, pickup_time, distance, duration, cancellation) VALUES
  (1, 1, '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  (2, 1, '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  (3, 1, '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  (4, 2, '2020-01-04 13:53:03', '23.4', '40', NULL),
  (5, 3, '2020-01-08 21:10:57', '10', '15', NULL),
  (6, 3, 'null', 'null', 'null', 'Restaurant Cancellation'),
  (7, 2, '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  (8, 2, '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  (9, 2, 'null', 'null', 'null', 'Customer Cancellation'),
  (10, 1, '2020-01-11 18:50:20', '10km', '10minutes', 'null');

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names (pizza_id, pizza_name) VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');

DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes (pizza_id, toppings) VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings (topping_id, topping_name) VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

-- 	A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL OR cancellation IN ('', 'null')
  AND pickup_time IS NOT NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(*) AS delivered_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
  AND ro.pickup_time IS NOT NULL
GROUP BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  customer_id,
  pn.pizza_name,
  COUNT(*) AS pizza_count
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY customer_id, pn.pizza_name
ORDER BY customer_id, pn.pizza_name;

-- 6. Maximum number of pizzas delivered in a single order:
SELECT co.order_id, COUNT(*) AS pizza_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
  AND ro.pickup_time IS NOT NULL
GROUP BY co.order_id
ORDER BY pizza_count DESC
LIMIT 1;

-- 7. Delivered pizzas with at least 1 change vs no changes (per customer):
SELECT
  customer_id,
  SUM(
    CASE
      WHEN (exclusions IS NOT NULL AND exclusions NOT IN ('', 'null'))
        OR (extras IS NOT NULL AND extras NOT IN ('', 'null')) THEN 1
      ELSE 0
    END
  ) AS changed_pizzas,
  SUM(
    CASE
      WHEN (exclusions IS NULL OR exclusions IN ('', 'null'))
        AND (extras IS NULL OR extras IN ('', 'null')) THEN 1
      ELSE 0
    END
  ) AS unchanged_pizzas
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
  AND ro.pickup_time IS NOT NULL
GROUP BY customer_id;

-- 8. Pizzas delivered with both exclusions and extras:
SELECT COUNT(*) AS pizzas_with_exclusions_and_extras
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
  AND ro.pickup_time IS NOT NULL
  AND (exclusions IS NOT NULL AND exclusions NOT IN ('', 'null'))
  AND (extras IS NOT NULL AND extras NOT IN ('', 'null'));

-- 9. Total volume of pizzas ordered per hour:
SELECT
  HOUR(order_time) AS hour,
  COUNT(*) AS total_orders
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY hour;

-- 10. Volume of orders per day of the week:
SELECT
  DAYNAME(order_time) AS day_of_week,
  COUNT(DISTINCT order_id) AS total_orders
FROM customer_orders
GROUP BY DAYNAME(order_time);

-- B. Runner and Customer Experience --

-- 1. Runners signed up by week (starting 2021-01-01)
SELECT 
  WEEK(registration_date, 1) AS week_number,
  COUNT(*) AS runners_signed_up
FROM runners
GROUP BY WEEK(registration_date, 1);

-- 2. Average time (minutes) from order to pickup by runner
SELECT
  ro.runner_id,
  ROUND(AVG(TIMESTAMPDIFF(MINUTE, co.order_time, STR_TO_DATE(ro.pickup_time, '%Y-%m-%d %H:%i:%s'))), 2) AS avg_pickup_delay
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE ro.pickup_time NOT IN ('null', '') AND ro.cancellation IS NULL
GROUP BY ro.runner_id;

-- 3. Is there a relation between number of pizzas and prep time?
SELECT
  co.order_id,
  COUNT(co.pizza_id) AS pizza_count,
  TIMESTAMPDIFF(MINUTE, MIN(co.order_time), STR_TO_DATE(ro.pickup_time, '%Y-%m-%d %H:%i:%s')) AS prep_time
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.pickup_time NOT IN ('null', '') AND ro.cancellation IS NULL
GROUP BY co.order_id;

-- 4. Average distance per customer
SELECT
  co.customer_id,
  ROUND(AVG(CAST(REPLACE(REPLACE(ro.distance, 'km', ''), ' ', '') AS DECIMAL(5,2))), 2) AS avg_distance_km
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.distance NOT IN ('null', '') AND ro.cancellation IS NULL
GROUP BY co.customer_id;

-- 5. Longest - shortest delivery times
SELECT 
  MAX(CAST(REPLACE(REPLACE(ro.duration, 'minutes', ''), 'mins', '') AS UNSIGNED)) -
  MIN(CAST(REPLACE(REPLACE(ro.duration, 'minutes', ''), 'mins', '') AS UNSIGNED)) AS delivery_time_diff
FROM runner_orders ro
WHERE ro.duration NOT IN ('null', '') AND ro.cancellation IS NULL;

-- 6. Average speed per delivery
SELECT
  ro.runner_id,
  ro.order_id,
  ROUND(
    CAST(REPLACE(REPLACE(ro.distance, 'km', ''), ' ', '') AS DECIMAL(5,2)) /
    (CAST(REPLACE(REPLACE(ro.duration, 'minutes', ''), 'mins', '') AS DECIMAL(5,2)) / 60),
    2
  ) AS avg_speed_kmh
FROM runner_orders ro
WHERE ro.duration NOT IN ('null', '') AND ro.distance NOT IN ('null', '') AND ro.cancellation IS NULL;

-- 7. Successful delivery percentage by runner
SELECT
  runner_id,
  ROUND(100 * SUM(CASE WHEN pickup_time NOT IN ('null', '') AND cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_pct
FROM runner_orders
GROUP BY runner_id;

-- C. Ingredient Optimization --

-- 1. Standard ingredients for each pizza
SELECT pn.pizza_name, pt.topping_name
FROM pizza_recipes pr
JOIN pizza_names pn ON pr.pizza_id = pn.pizza_id
JOIN pizza_toppings pt ON FIND_IN_SET(pt.topping_id, pr.toppings) > 0
ORDER BY pn.pizza_name, pt.topping_name;

-- 2. Most commonly added extra
SELECT extras, COUNT(*) AS freq
FROM customer_orders
WHERE extras NOT IN ('null', '', NULL)
GROUP BY extras
ORDER BY freq DESC
LIMIT 1;

-- 3. Most common exclusion
SELECT exclusions, COUNT(*) AS freq
FROM customer_orders
WHERE exclusions NOT IN ('null', '', NULL)
GROUP BY exclusions
ORDER BY freq DESC
LIMIT 1;

-- D. Pricing and Ratings --

-- 1. Total revenue (Meatlovers $12, Vegetarian $10)
SELECT
  SUM(CASE
      WHEN pn.pizza_name = 'Meatlovers' THEN 12
      WHEN pn.pizza_name = 'Vegetarian' THEN 10
  END) AS total_revenue
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.pickup_time NOT IN ('null', '') AND ro.cancellation IS NULL;

-- 2. Revenue with $1 per extra
-- Note: extras column is comma-separated string
SELECT
  SUM(CASE
      WHEN pn.pizza_name = 'Meatlovers' THEN 12
      WHEN pn.pizza_name = 'Vegetarian' THEN 10
  END + 
  CASE
      WHEN co.extras NOT IN ('null', '', NULL) THEN LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', '')) + 1
      ELSE 0
  END) AS total_revenue_with_extras
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.pickup_time NOT IN ('null', '') AND ro.cancellation IS NULL;

-- 3. Ratings Table (design + insert)
CREATE TABLE ratings (
  order_id INT,
  runner_id INT,
  rating INT CHECK (rating BETWEEN 1 AND 5)
);

INSERT INTO ratings (order_id, runner_id, rating) VALUES
  (1, 1, 5), (2, 1, 4), (3, 1, 4), (4, 2, 3), (5, 3, 5), (7, 2, 4), (8, 2, 5), (10, 1, 5);

-- 4. Join all delivery info
SELECT
  co.customer_id,
  ro.order_id,
  ro.runner_id,
  r.rating,
  co.order_time,
  ro.pickup_time,
  TIMESTAMPDIFF(MINUTE, co.order_time, STR_TO_DATE(ro.pickup_time, '%Y-%m-%d %H:%i:%s')) AS time_to_pickup,
  ro.duration,
  ROUND(
    CAST(REPLACE(ro.distance, 'km', '') AS DECIMAL(5,2)) /
    (CAST(REPLACE(ro.duration, 'minutes', '') AS DECIMAL(5,2)) / 60), 2
  ) AS avg_speed,
  COUNT(co.pizza_id) AS total_pizzas
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN ratings r ON ro.order_id = r.order_id
WHERE ro.pickup_time NOT IN ('null', '') AND ro.cancellation IS NULL
GROUP BY ro.order_id;

-- 5. Profit after $0.30/km runner pay
SELECT
  SUM(
    CASE
      WHEN pn.pizza_name = 'Meatlovers' THEN 12
      WHEN pn.pizza_name = 'Vegetarian' THEN 10
    END
  ) - SUM(CAST(REPLACE(ro.distance, 'km', '') AS DECIMAL(5,2)) * 0.30) AS profit_after_runner_cost
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.pickup_time NOT IN ('null', '') AND ro.cancellation IS NULL;
