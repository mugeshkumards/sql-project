-- SCHEMA & TABLE CREATION

CREATE SCHEMA IF NOT EXISTS dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales (customer_id, order_date, product_id) VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu (product_id, product_name, price) VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members (customer_id, join_date) VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. Total amount spent per customer
SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. Visit days per customer
SELECT customer_id, COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id;

-- 3. First item purchased by each customer
SELECT customer_id, product_name
FROM (
  SELECT s.customer_id, s.order_date, s.product_id, m.product_name,
         RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rk
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
) t
WHERE rk = 1;

-- 4. Most purchased item overall
SELECT m.product_name, COUNT(*) AS times_purchased
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;

-- 5. Most popular item per customer
SELECT customer_id, product_name
FROM (
  SELECT s.customer_id, m.product_name,
         COUNT(*) AS cnt,
         RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rk
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
) t
WHERE rk = 1;

-- 6. First item after joining
SELECT customer_id, product_name
FROM (
  SELECT s.customer_id, s.order_date, m.product_name,
         RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rk
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  JOIN members mb ON s.customer_id = mb.customer_id
  WHERE s.order_date >= mb.join_date
) t
WHERE rk = 1;

-- 7. Item before becoming a member
SELECT customer_id, product_name
FROM (
  SELECT s.customer_id, s.order_date, m.product_name,
         RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rk
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  JOIN members mb ON s.customer_id = mb.customer_id
  WHERE s.order_date < mb.join_date
) t
WHERE rk = 1;

-- 8. Total items and spend before joining
SELECT s.customer_id, COUNT(*) AS total_items, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;

-- 9. Points earned with sushi 2x
SELECT s.customer_id,
  SUM(
    CASE
      WHEN m.product_name = 'sushi' THEN m.price * 20
      ELSE m.price * 10
    END
  ) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. Points with 2x bonus for 7 days after join
SELECT s.customer_id,
  SUM(
    CASE
      WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 6 DAY)
        THEN m.price * 20
      WHEN m.product_name = 'sushi'
        THEN m.price * 20
      ELSE m.price * 10
    END
  ) AS bonus_week_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;
